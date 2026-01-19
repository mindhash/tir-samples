
# ==============================================================================
# Direct Slurm Launch with sbatch (Alternative to NeMo-Run)
# ==============================================================================

# ==============================================================================
# CONFIGURATION - Modify these for your setup
# ==============================================================================

# Training script to run
TRAINING_SCRIPT="/pfs/pretraining/gemma3_pretrain.py"

# ==============================================================================
# Environment Setup
# ==============================================================================

# Set common environment variables
export TORCH_NCCL_AVOID_RECORD_STREAMS=1
export NCCL_NVLS_ENABLE=0

# Authentication tokens (uncomment and set your tokens)
# EDIT: must add your hf token here 
export HF_TOKEN=<SET_TOKEN_HERE>

# optional: uncomment if needed 
# export WANDB_API_KEY="your_wandb_key_here"

# Optional: Uncomment if needed
# export CUDA_DEVICE_MAX_CONNECTIONS=1
export NCCL_DEBUG=WARN

# ==============================================================================
# Job Execution
# ==============================================================================

echo "======================================"
echo "Gemma3  Training Job"
echo "======================================"
echo "Job ID: $SLURM_JOB_ID"
echo "Nodes: $SLURM_JOB_NUM_NODES"
echo "GPUs per node: $SLURM_GPUS_PER_NODE"
echo "Script: $TRAINING_SCRIPT"

if [ -n "$HF_TOKEN" ]; then
    echo "HF_TOKEN: Set"
fi
if [ -n "$WANDB_API_KEY" ]; then
    echo "WANDB_API_KEY: Set"
fi
echo "======================================"

# Determine script path
SCRIPT_PATH="${TRAINING_SCRIPT}"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "ERROR: Training script not found: $SCRIPT_PATH"
    exit 1
fi

MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)
MASTER_PORT=6000
NODE_RANK=$SLURM_PROCID

echo "MASTER_ADDR: $MASTER_ADDR" 
echo "NODE_RANK: $NODE_RANK" 

# Make sure the hf devices in the list below are correct. use the below command to confirm you have same devices for infiniband. 
# ibv_devinfo | sed -n -e '/hca_id/p' -e '/link_layer:/p' | grep -B1 InfiniBand | grep hca_id | sed -e 's/^hca_id://g' | tr -d '[[:blank:]]' | sed 's/$/:1/' | paste -sd ","

CMD="export NCCL_SOCKET_IFNAME=eth0;export NCCL_IB_HCA=mlx5_0:1,mlx5_3:1,mlx5_4:1,mlx5_5:1,mlx5_6:1,mlx5_9:1,mlx5_10:1,mlx5_11:1; export MASTER_ADDR=$MASTER_ADDR;export MASTER_PORT=$MASTER_PORT;export NODE_RANK=$NODE_RANK; python3 $SCRIPT_PATH"

echo "Executing: $CMD"
echo "======================================"


# Build srun command (always containerized)
SRUN_CMD="srun "


$SRUN_CMD bash -c "$CMD" 

echo "======================================"
echo "Job completed"
echo "======================================"
