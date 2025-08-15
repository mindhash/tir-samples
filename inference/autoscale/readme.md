

### Optimise Startup time when auto-scaling
1. Reduce Model Download Time: 
   - Use Shared file system (SFS) to load models. When launching a TIR endpoint, you can choose SFS as model cache store instead of local disk (PV). In this way, the replicas will use the already downloaded model and come online faster.
   - If SFS is not an option then the other alternative is to scale replicas to max no of replicas and then scale down to min replicas. In this mode, each replica will re-use the local disk (PV) which already has model downloaded.

2. Reduce Container Image Download: TIR  prioritises scheduling images to nodes where inference has already run. In rare scenarios, the image may go to new nodes. To further optimise this, you can reserve a private cluster and launch all your inference on this cluster. If you have multiple endpoints, they will scale using the same nodes. 

3. Reduce Model loading to GPU time:
   - For vllm, You can also increase the max parallel loading workers to 4. This will allow load the models to gpus in parallel. Other inference engines may have a similar setting.
   - Using Cuda Checkpoint is an option for limited scenarios. It would work if you have a single gpu workload. Also requires special setup considerations. Please reach out to our team if you are a looking to go this route. 

