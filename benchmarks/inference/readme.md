


### Inference Latency
When benchmarking on gpu performance, it is important to focus just on inference latency. This offers a comparable view across different gpus and providers. 

#### steps
1. Start a new gpu instance in TIR. Choose the `vllm` environment.
   <img width="825" height="761" alt="image" src="https://github.com/user-attachments/assets/cad05293-052c-455e-b785-47e61484319c" />

2. Start a terminal. Set HF token
   ```
   $ huggingface-cli login --token  <your-token-here>
   ```
   
2. In terminal, run the benchmark 
```
$ vllm bench serve  --model google/gemma-3-27b-it  --random-input-len 1000 --random-output-len 1000 --random-batch-size 4 --base-url  <tir-endpoint-http-full-path e.g https://infer.e2enetworks.net/project/p-f3r34r/endpoint/is-d3234324d/ 
> --header x-auth-token=<tir-auth-token-here.e.g.-eyjgkv..>
```


