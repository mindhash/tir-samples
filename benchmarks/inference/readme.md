


### Inference Latency
When benchmarking on gpu performance, it is important to focus just on inference latency. This offers a comparable view across different gpus and providers. 

#### steps
1. Start a new cpu instance in TIR. Choose the `transformers` environment.
   <img width="825" height="761" alt="image" src="https://github.com/user-attachments/assets/cad05293-052c-455e-b785-47e61484319c" />

2. Start a terminal and Install vllm (0.12.0). The vllm version here should ideally match with the version selected during creation of inference endpoint in TIR
   ```
   $ pip install vllm==v0.12.0
   ```
2. In terminal, checkout vllm(0.12.0) version
```
$ git clone https://github.com/vllm-project/vllm.git --branch v0.12.0
$ cd vllm
```
3. 
