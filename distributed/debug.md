### Troubleshooting NCCL errors

If your script fails due to NCCL error, then there two things to mainly look at: 
1. The nccl error is an effect and not the cause. look into the failure log closely if there are other application errors. In a distributed setup, nccl error is always present because a failed worker will break the connection and result in nccl error in log.
2. The nodes are unable to communicate

Now, if you have confirmed that #1 is no the reason for failure, then do the following steps:
1. Run the following on each nodes before running your training script: `export NCCL_DEBUG=INFO`
2. The step 1 will generate additional log when your script runs. Capture the log and share it with support team. 
3. If you are using slurm, then run the following steps to confirm the node communcation issue:
   ```
   $ cd /tmp
   $ apt update && apt install git # optional 
   $ git clone https://github.com/mindhash/tir-samples
   $ cd tir-samples/distributed
   $ sinfo    ## ensure all slurm nodes are active 
   $ sbatch all_reduce.slurm
   $ squeue    ## to monitor slurm job 
   ```
   Once the slurm job complets, you will notice log / out file (for same job id - all_reduce_<job_id>.out) in the same directory. Send this file to support team.

The above steps will help the support team to resolve the issue faster. 
