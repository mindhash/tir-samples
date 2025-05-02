
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

1. Download and pre-process sample data 
```
$ python3 /opt/NeMo-Aligner/examples/nlp/data/steerlm/preprocess_openassistant_data.py --output_directory=/shared/nemo/data
```

2. Convert HF model to Nemo Format 

```
$ huggingface-cli login --token <YOUR_HF_TOKEN>
$ export HF_HOME=/shared/hf_cache
$ huggingface-cli download meta-llama/Meta-Llama-3-8B
$ python /opt/NeMo/scripts/checkpoint_converters/convert_llama_hf_to_nemo.py --input_name_or_path /shared/hf_cache/hub/models--meta-llama--Meta-Llama-3-8B/snapshots/8cde5ca8380496c9a6cc7ef3a8b46a0372a1d920 --output_path /shared/nemo_format/models/llama3-8b/mcore_gpt.nemo
$ cd /shared/nemo_format/models/llama3-8b
$ untar -xvf mcore_gpt.nemo
```

3. Create training script
 
```
$ vi /shared/nemo-llama3-8b-finetune.sh
```

4. Edit (no of nodes, dataset) and copy the following contents to nemo-llama3-8b-finetune.sh: 

```
#!/bin/bash

#SBATCH -p all
#SBATCH --nodes 1  
#SBATCH -t 24:00:00
#SBATCH -J llama3-8b-sft
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8
#SBATCH --exclusive
#SBATCH --overcommit
#SBATCH --open-mode=append

GPFS="/opt/NeMo-Aligner"

TRAIN_DATA_PATH="/shared/nemo/data/oasst/train.jsonl"
VALID_DATA_PATH="/shared/nemo/data/oasst/val.jsonl"


PROJECT=WANDB_PROJECT # if you want to use wandb

RESULTS_DIR="/shared/nemo/result_dir"

OUTFILE="${RESULTS_DIR}/sft-%j-%t.out"
ERRFILE="${RESULTS_DIR}/sft-%j-%t.err"
mkdir -p ${RESULTS_DIR}


read -r -d '' cmd <<EOF
echo "*******STARTING********" \
&& echo "---------------" \
&& echo "Starting training" \
&& cd ${GPFS} \
&& export PYTHONPATH="${GPFS}:${PYTHONPATH}" \
&& export HYDRA_FULL_ERROR=1 \
&& export NCCL_SOCKET_IFNAME=eth0 \
&& export NCCL_DEBUG=WARN \
&& export NCCL_IB_MERGE_NICS=0 \
&& export NEMO_CACHE_MODELS=/shared/hf_cache \
&& export NEMO_CACHE_DIR=/shared/hf_cache \
&& python -u ${GPFS}/examples/nlp/gpt/train_gpt_sft.py \
   trainer.precision=bf16 \
   trainer.num_nodes=${SLURM_JOB_NUM_NODES} \
   trainer.devices=8 \
   trainer.sft.max_steps=10000000 \
   trainer.sft.limit_val_batches=0 \
   trainer.sft.val_check_interval=10000 \
   model.megatron_amp_O2=True \
   model.tensor_model_parallel_size=8 \
   model.resume_from_checkpoint=/shared/nemo/checkpoints \
   model.optim.lr=5e-6 \
   model.data.chat=True \
   model.data.num_workers=0 \
   model.data.train_ds.micro_batch_size=8 \
   model.data.train_ds.global_batch_size=8 \
   model.data.train_ds.file_path=${TRAIN_DATA_PATH} \
   model.data.train_ds.max_seq_length=8064 \
   model.data.validation_ds.micro_batch_size=8 \
   model.data.validation_ds.global_batch_size=8 \
   model.data.validation_ds.file_path=${VALID_DATA_PATH} \
   model.data.validation_ds.max_seq_length=8064 \
   exp_manager.create_wandb_logger=False \
   exp_manager.explicit_log_dir=${RESULTS_DIR} \
   exp_manager.wandb_logger_kwargs.project=${PROJECT} \
   exp_manager.wandb_logger_kwargs.name=chat_sft_run \
   exp_manager.resume_if_exists=True \
   exp_manager.resume_ignore_no_checkpoint=True \
   exp_manager.create_checkpoint_callback=True \
   exp_manager.checkpoint_callback_params.save_nemo_on_train_end=True \
   exp_manager.checkpoint_callback_params.monitor=validation_loss \
   model.restore_from_path=/shared/nemo_format/models/llama3-8b \
   +model.restore_from_ckpt=/shared/nemo_format/models/llama3-8b \
   ++trainer.fast_dev_run=true 
EOF

# +trainer.fast_dev_run=True

srun -o $OUTFILE -e $ERRFILE bash -c "${cmd}"
set +x
```
6. Submit the slurm job

```
$ sbatch nemo-llama3-8b-finetune.sh
```

7. Monitor the job
```
$ squeue
```

8. Monitor the log
```
$ cd result_dir
$ cat sft*_0.err
$ cat sft*_0.out
```
 



