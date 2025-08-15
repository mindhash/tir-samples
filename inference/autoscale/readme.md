
### Sample Autoscaling Config

#### Sample Configuraton 1
**Metric:** concurrent request 
**Target Value:** 10
**Initial Cooldown Period:** 900
**Idle Timeout:** 900 

With this in place, we are asking autoscaler to allow 10 concurrent requests to each replica.  

Some scenarios to explain this further:

1. Service receives 100 requests, current active replicas are 4
       Action: Autoscaler will find out how many replicas are needed to process 100 requests (100/10). It will launch 6 more replicas to meet the demand. 

2. ⁠Service receives 10 requests, current active replicas are 4. Min replica 4 
       Action: Autoscaler will not perform any action. As min replica is 4. even if it knows you only need one replica to process 10 requests.  The requests are evenly distributed across 4 replicas. 


### Optimise Startup time when auto-scaling
1. Reduce Model Download Time: 
   - Use Shared file system (SFS) to load models. When launching a TIR endpoint, you can choose SFS as model cache store instead of local disk (PV). In this way, the replicas will use the already downloaded model and come online faster.
   - If SFS is not an option then the other alternative is to scale replicas to max no of replicas and then scale down to min replicas. In this mode, each replica will re-use the local disk (PV) which already has model downloaded.

2. Reduce Container Image Download: TIR  prioritises scheduling images to nodes where inference has already run. In rare scenarios, the image may go to new nodes. To further optimise this, you can reserve a private cluster and launch all your inference on this cluster. If you have multiple endpoints, they will scale using the same nodes. 

3. Reduce Model loading to GPU time:
   - For vllm, You can also increase the max parallel loading workers to 4. This will allow load the models to gpus in parallel. Other inference engines may have a similar setting.
   - Using Cuda Checkpoint is an option for limited scenarios. It would work if you have a single gpu workload. Also requires special setup considerations. Please reach out to our team if you are a looking to go this route. 

