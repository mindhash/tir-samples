
# Getting Started with Slurm


## Useful Commands 

### Log into the head node

```
ssh admin@<ip>
```

You can find the connect instructions from TIR dashboard. If you dont have access to TIR dashboard, contact your admin to setup your account. 

<img width="860" alt="image" src="https://github.com/user-attachments/assets/dd7dbf19-7703-4f6a-8873-1a02db3bd4c9" />


### Check the node are up and active 
```
sinfo 
```

If you notice inactive nodes then restart the slurm services on all nodes from TIR dashbaord >> Deployments >> Choose your deployment >> Actions (column) >> Restart Slurm Services 

<img width="394" alt="Screenshot 2025-05-02 at 11 11 59 AM" src="https://github.com/user-attachments/assets/c1a91eb4-251c-441c-b220-4afbfe13540a" />



### Submit a job

```
sbatch <script>.sh
```

Sample header of a slurm script. Use the partion name - all. 

```
#!/bin/bash

#SBATCH -p all
#SBATCH --nodes <NO_OF_NODES>
#SBATCH -t 24:00:00
#SBATCH -J <JOB_NAME>
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8


### Optional to restrict job to run on certain nodes. 
##SBATCH --nodelist=slurm-480-slurmd-1,slurm-480-slurmd-2 

```

### Status of running jobs
```
squeue
```

### See details of active Jobs  
```
scontrol show jobs 
```

### Download/Sync datasets for training 

```
# Run the following command from your local system or VM (E2E or other providers). You can find the IP of training cluster from TIR dashboard in `Connect` section.  We recommend storing all your data and training scripts in /shared for persistence. Content stored anywhere else may not be persistent across restarts.  
$ rsync /my-local/squad.jsonl admin@<ip>:/shared/data/
```

### Download model or dataset from HF 
We recommend setting env variable `HF_HOME` to `/shared/hf_cache` before running the following command or any script that downloads models from HF. This will ensure, other nodes dont download the model or dataset again. 

```
pip install huggingface_hub
hugginface-cli login --token <TOKEN>

# model download 
huggingface-cli download <MODEL>

# dataset download 
huggingface-cli download --repo-type <DATASET>
```

### Log into the worker nodes
You can submit jobs from login node. But sometimes, you may want to access worker node for debugging.  This requires configuration of SSH forwarding on your local machine. The steps are also available in TIR dashboard, in connect section of worker node. 

**Perform these steps on your local machine and not on any nodes from your cluster ** 

```
$ vim ~/.ssh/config
```

Add the following lines. Please note, if you dont have default name for identity file then change it below. 

```
Host *
    ForwardAgent yes
    UseKeychain yes  # macOS only
    AddKeysToAgent yes  
    IdentityFile ~/.ssh/id_rsa
```

Restart SSH Agent. The step may differ on windows 

```
$ eval "$(ssh-agent -s)"
$ ssh-add ~/.ssh/id_rsa
```

Now you can ssh on to worker node from head/login node. Please note, you can not directly ssh onto worker node, you always need to go through login/head node. 

```
ssh admin@<head-node-ip>
```

## Working with Nemo 
TIR supports both Nemo 1.x and 2.x versions. Let us test llama3-8b SFT training example below. 

Create a file `nemo-
```




