# Inference Optimisation stories 

## 1. Introduction 
- Real-world scaling across LLM, Stable Diffusion, ASR, and TTS
- Goals: latency, throughput, GPU efficiency, cost per request
- real-world challenges: streaming latency, unpredictable request rate, cold starts, burst traffic, multimodal pipelines

## 2. Prompt-Level & Input Optimisations
  Reduce model work before it begins

- **kv-Reuse**: It is often easy to overlook simple solutions when optimising any peice of software. The most expensive operation in LLMs is KV Calcuation. It is unavoidable. You don't want to repeat it. Every inference engine like vLLM, tensor-rt LLM understands it and provides a reuse mechanism. When we observed endpoint metrics, there was hardly any kv cache hits. 

## Scaling vLLM Inference Throughput/Latency for mixed lengths request (input tokens varying from 1000 to 20000 and generations 100-2000)

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
