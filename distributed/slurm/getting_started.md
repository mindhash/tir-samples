
# Getting Started with Slurm


## Useful Commands 

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

## Working with Nemo 



