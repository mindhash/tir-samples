#!/bin/bash

#SBATCH --job-name=nccl-launcher
#SBATCH --nodes=8   ## Edit based on no of ndoes 
##SBATCH --nodelist=  # EDIT if you wnat to run on specific nodes, enter node names here
#SBATCH --ntasks-per-node=1          
#SBATCH --cpus-per-task=160           
#SBATCH --gres=gpu:8                 
#SBATCH --time=0:10:00               # EDIT the desired runtime
#SBATCH --exclusive
#SBATCH --partition=all      
#SBATCH --output=%x-%j.out

echo "START TIME: $(date)"

# auto-fail on any errors in this script
set -eo pipefail

# logging script's variables/commands for future debug needs
set -x

# EDIT the python venv name here. not needed for this script if node has torch installed
# source /shared/python_env/bin/activate

# its assumed that script will be placed under nccl-slurm folder in /shared drive along with all_reduce.py 
cd /shared/tir-samples

# main log is written here 
LOG_PATH="main_log.txt"

GPUS_PER_NODE=8
NNODES=$SLURM_NNODES

# define the node 0 hostname:port
MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)
MASTER_PORT=6000

LAUNCHER="python3 -u -m torch.distributed.run \
    --nproc_per_node 1 \
    --nnodes $NNODES \
    --rdzv_endpoint $MASTER_ADDR:$MASTER_PORT \
    --rdzv_backend c10d \
    --max_restarts 0 "
    
# EDIT: location of python file if needed. The all_reduce.py is available here: https://github.com/mindhash/tir-samples/blob/master/distributed/all_reduce.py
PROGRAM="/shared/tir-samples/distributed/all_reduce.py "

export CMD="export NCCL_DEBUG=INFO; export NCCL_SOCKET_IFNAME=eth0; export NCCL_NET=IB; $LAUNCHER $PROGRAM"

echo $CMD

# EDIT if you want to redirect /tmp to /scratch (some local SSD path) since /tmp is tiny on compute nodes
# export TMPDIR=/scratch

export NCCL_DEBUG=INFO

# to unravel async errors w/o the correct traceback - potentially makes everything very slower
# export CUDA_LAUNCH_BLOCKING=1

# to force crashing on nccl issues like hanging broadcast
# export NCCL_ASYNC_ERROR_HANDLING=1

# srun error handling:
# --wait=60: wait 60 sec after the first task terminates before terminating all remaining tasks
# --kill-on-bad-exit=1: terminate a step if any task exits with a non-zero exit code
SRUN_ARGS=" \
    --wait=60 \
    --kill-on-bad-exit=1 \
    --jobid $SLURM_JOB_ID \
    "

# bash -c is needed for the delayed interpolation of env vars to work
srun $SRUN_ARGS bash -c "$CMD" 2>&1 | tee -a $LOG_PATH

echo "END TIME: $(date)"
