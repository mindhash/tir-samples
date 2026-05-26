#!/bin/bash

#SBATCH --job-name=nccl-broadcast
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=32
#SBATCH --exclusive
#SBATCH --partition=all
#SBATCH --time=00:10:00
#SBATCH --output=%x-%j.out

set -eo pipefail
set -x

echo "START TIME: $(date)"

cd /shared/tir-samples

MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)
MASTER_PORT=6000

export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,COLL

# single rail first
export NCCL_IB_HCA="mlx5_4:1;mlx5_5:1;mlx5_6:1;mlx5_7:1;mlx5_8:1;mlx5_11:1;mlx5_12:1;mlx5_13:1"

export NCCL_SOCKET_IFNAME=eth0

# simplify NCCL behavior
export NCCL_COLLNET_ENABLE=0
export NCCL_SHARP_DISABLE=0
export NCCL_PROTO=Simple
export NCCL_ALGO=Ring

# useful for debugging
export TORCH_DISTRIBUTED_DEBUG=DETAIL

LAUNCHER="python3 -u -m torch.distributed.run \
    --nproc_per_node=1 \
    --nnodes=$SLURM_NNODES \
    --rdzv_backend=c10d \
    --rdzv_endpoint=$MASTER_ADDR:$MASTER_PORT \
    --max_restarts=0"

PROGRAM="/shared/tir-samples/distributed/broadcast.py"

SRUN_ARGS=" \
    --container-image=/shared/images/pytorch-26.04.sqsh \
    --network=host \
    --container-mounts=/shared/amol/tir-samples:/shared/tir-samples \
    --wait=60 \
    --kill-on-bad-exit=1 \
    --jobid=$SLURM_JOB_ID \
"

srun $SRUN_ARGS bash -c '$LAUNCHER $PROGRAM'

echo "END TIME: $(date)"
