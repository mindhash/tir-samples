# Inference Optimisation Strategies 

## 1. Introduction 
- Real-world scaling across LLM, Stable Diffusion, ASR, and TTS
- Goals: latency (TTFT/ITL/E2E), throughput, GPU efficiency, cost per request
- real-world challenges: streaming latency, unpredictable request rate, cold starts, burst traffic, multimodal pipelines

## 2. Inference Engines
- First and foremost - use an inference engine like vLLM or Triton + TensorRT-LLM whenever possible. Its a no-brainer as these engines support `continous batching`. The idea of continous batching is simple - Inference goes through a series of forward passes through a neural network. Continous batching will allow processing requests together even if they dont arrive at the same time. 
- While contious batching is the best thing there is, for some generative cases like image (stable diffusion), audio (ASR or TTS), this may not be always an option. This is for 2 reasons:
  (i) if you are working with open source model which doesn't have a batch dimention
  (ii) vLLM does not support your model.
- If you are constrained by option # 1 above, you have 3 options:
  1. Use MIG to launch multiple containers on same gpu. You can go upto 7 parallel inference servers on same GPU. This is supported with full node access only. 
  2. In such cases, batching can only be done through multi-processing. Don't re-invent the wheel. Triton supports multiple instances option which can spawn several python processes with separate cuda stream. This is best option to leverage gpu capabilities in parallel. If you are thinking - I will use multi-threading - then don't. Multi-threading does not guarantee parallel execution on gpu. 
- If you are constrainted by option # 2, go with triton server. Convert your model to ONNX format for best results and performance.
- As a last option, consider building your own flask or fast api to handle model inference. In this case, ensure your processing engine can run in its own python process (explore python multi-processing module). Use a queue to send async requests from flask POST method to processing engine.  
  
## 2. Prompt-Level & Input Optimisations  
  Reduce model work before it begins. 

  Note: This section will mostly fit for transformer based inference. 

  - **kv-reuse**: When optimising, major gains often come from not having to do some things. The most expensive operation in LLMs is KV Calcuation. It is unavoidable. But you don't want to repeat it. Every inference engine like vLLM, tensor-rt LLM understands it and provides a reuse mechanism.  Enable prefix_caching to re-use kv within or across requests. This only works when your requests share first few sentencese in prompts which is often the case for multi-turn conversations. vLLM uses a hash function to determine if two sentences are alike and decide if kv tensors can be re-used.
  - Organize your prompts in this manner - <static system prompt> <static part of user prompt e.g. part that doesnt change often across similar type of requests> <dynamic part of user prompt e.g. variables, facts etc>. This will ensure maximum kv re-use. 
  - Minimise dynamic part of prompts. This is easier said than done.  Developers are often responsible for writing prompts and performance is often kept as a last bite to chew. You will need to keep tracking prompts in your production and run a simple cluster algo to see how spread out your prompts are.  

## 3. Optimise vLLM Engine
  Request-level Inference is state-less shared nothing architecture. This helps us optimise engine like vLLM in isolation and scale horizontally without any drop in performance (assuming network routing and load balancing works as expected).  

### Model Selection and GPU sizing 
- Choose FP8 version almost every time. If you have concerns around quality, generate a fp8 version by using your samples. If not, AWQ on average generally performs well. 
- The layout of GPU memory need for inference can be split into (static) and (dynamic) parts. The static part curresponds to overall memory used to store model and some functional elements around it. The dynamic part covers the per request memory requirement.
  
  * static: (model size in parameters * bytes per parameter)
  * per request: (prompt + generated tokens * 0.5MB to 1 MB per token) 

- When working with text based inference, per request memory is really important as it can help decide the no of requests engine can process at once. It can also impact the latency. For example, if you ask vLLM to load entire free space e.g. 80GB with requests before every batch iteration, you will experience with a higher TTFT (time to first token) request latency. So if TTFT is important to you, optimise for a batched tokens to match your latency requirement. On the other hand, if throughput is important (total tokens gpu generates per second) then go ahead and load up entire gpu before each iteration to utilise complete capacity(TFLOPS) of gpu.  

### Batching 
  - Control Batch Size: 

### TTFT

### End-to-End Latency 

### Throughput 

### Start-up time for Auto-scaling  
The key components of startup are often amoung -> `Model Download`, `Load Model to GPU`, `Torch Compile`, and `Cuda Graph` calculation 
- Use a local peristent model cache to avoid repeated model downloads on restarts. TIR uses a shared drive to support model persistence.
- Look into setting specific [Cuda graph](https://docs.vllm.ai/en/latest/design/cuda_graphs.html#cudagraphmodes) you need.
- Optimise torch compile time by storing compiled files to persistent location. In TIR, this is /mnt/models

## 3. Request routing 



## Case studies and Examples 
### Scaling vLLM Inference Throughput/Latency for mixed lengths request (input tokens varying from 1000 to 20000 and generations 100-2000)

1. Create separate instance to handle long (>5k) and short prompt (<5k). On client side, you can also do this with approximate character count.
2. Use quantized versions whenever possible. Instead of full 70B, use FP8 version or INT4. When using INT4 version, don't use multiple GPUs. 
4. First decide minimum GPUs you would need for best performance for the model. For e.g. INT4 runs best with a single H100 or H200. In this case, create an endpoint with single GPU. And then scale replicas. For FP8 version, 2 gpus offer good results, and for full LLAMA3  version 4 gpus are good start. Just adding more gpus to same replica will not offer throughput/latency improvements.  It is better to start with a replica with optimal gpu config and scale horizontally. In TIR, this would be just matter of increasing workers from `serverless configuration` tab.

  <img width="1264" height="476" alt="image" src="https://github.com/user-attachments/assets/6193ffbc-8851-44ca-8f84-a0c4f0c4f1cb" />

3. Optimise the request flow to the vllm endpoints. VLLM does not reject requests if max_seq_len is set to a high threshold. This also creates problem as VLLM will prioritise new requests. You will start noticing tail latency increase. as show below:
  <img width="754" height="220" alt="image" src="https://github.com/user-attachments/assets/c4bf27d8-dbc4-44d6-887f-6ba600828d44" />

  To reduce this effect, set a max_seq_len based on ideal concurrent request that vllm can process. Typically 48-64 is fine for prompt sizes of 2000-5000.
  A good way to achieve this is to use a semaphore in python. 
  ```
    semaphore = threading.Semaphore(48)
  ```
3. Make sure the request flow is consistent. If the vllm does not have enough requests to process, you will not be utilising complete GPU. You can find running requests in TIR monitoring tab of endpoint.
   <img width="1244" height="639" alt="image" src="https://github.com/user-attachments/assets/a51aa30c-dfb4-47ff-a685-866730c31313" />

5. Set long_prefix_threshold to 5000 for endpoints that process shorter prompts. This will ensure longer prompt even if it arrives at this endpoint, will not cause delay to regular requests.


## VLLM Specific Optimization
- In Endpoint, set the environment variable `VLLM_CACHE_ROOT=/mnt/models/.cache` to re-use torch compile and cuda graph compliled files. When this is set, you should see a message like below in the log. This means, on worker restarts the compile and cuda graph capture steps will be much quicker. 

```
INFO 08-25 02:04:47 [backends.py:459] Using cache directory: /mnt/models/.cache/torch_compile_cache/50121da10f/rank_0_0 for vLLM's torch.compile
```



@

@@
