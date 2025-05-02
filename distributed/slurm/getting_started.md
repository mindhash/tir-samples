
# Getting Started with Slurm


## Commands 

### Check the node are up and active 
```
sinfo 
```

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

