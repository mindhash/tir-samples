
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
 



## Working with Nemo ASR

1. Download sample data

 ```
# for the original source, please visit http://www.speech.cs.cmu.edu/databases/an4/an4_sphere.tar.gz
$ cd /shared
$ mkdir -p nemo_asr/data
$ cd nemo_asr/data
$ wget https://dldata-public.s3.us-east-2.amazonaws.com/an4_sphere.tar.gz  

```


2. Pre-process data for Nemo Processing. 
```
$ vi preprocess.py
```
Copy the following  contents  to `preprocess.py`

```

# Original Source code: https://docs.nvidia.com/deeplearning/riva/user-guide/docs/tutorials/asr-finetune-parakeet-nemo.html

import json, librosa, os, glob
import subprocess

DATA_DIR = os.getcwd()
os.environ["DATA_DIR"] = DATA_DIR

source_data_dir = f"{DATA_DIR}/an4"
target_data_dir = f"{DATA_DIR}/an4_converted"

def an4_build_manifest(transcripts_path, manifest_path, target_wavs_dir):
    """Build an AN4 manifest from a given transcript file."""
    with open(transcripts_path, 'r') as fin:
        with open(manifest_path, 'w') as fout:
            for line in fin:
                # Lines look like this:
                # <s> transcript </s> (fileID)
                transcript = line[: line.find('(') - 1].lower()
                transcript = transcript.replace('<s>', '').replace('</s>', '')
                transcript = transcript.strip()

                file_id = line[line.find('(') + 1 : -2]  # e.g. "cen4-fash-b"
                audio_path = os.path.join(target_wavs_dir, file_id + '.wav')

                duration = librosa.core.get_duration(filename=audio_path)

                # Write the metadata to the manifest
                metadata = {"audio_filepath": audio_path, "duration": duration, "text": transcript}
                json.dump(metadata, fout)
                fout.write('\n')

"""Process AN4 dataset."""
if not os.path.exists(source_data_dir):
    link = 'http://www.speech.cs.cmu.edu/databases/an4/an4_sphere.tar.gz'
    raise ValueError(
        f"Data not found at `{source_data_dir}`. Please download the AN4 dataset from `{link}` "
        f"and extract it into the folder specified by the `source_data_dir` argument."
    )

# Convert SPH files to WAV files
sph_list = glob.glob(os.path.join(source_data_dir, '**/*.sph'), recursive=True)
target_wavs_dir = os.path.join(target_data_dir, 'wavs')
if not os.path.exists(target_wavs_dir):
    print(f"Creating directories for {target_wavs_dir}.")
    os.makedirs(os.path.join(target_data_dir, 'wavs'))

for sph_path in sph_list:
    wav_path = os.path.join(target_wavs_dir, os.path.splitext(os.path.basename(sph_path))[0] + '.wav')
    cmd = ["sox", sph_path, wav_path]
    subprocess.run(cmd, check=True)

# Build AN4 manifests
train_transcripts = os.path.join(source_data_dir, 'etc/an4_train.transcription')
train_manifest = os.path.join(target_data_dir, 'train_manifest.json')
an4_build_manifest(train_transcripts, train_manifest, target_wavs_dir)

test_transcripts = os.path.join(source_data_dir, 'etc/an4_test.transcription')
test_manifest = os.path.join(target_data_dir, 'test_manifest.json')
an4_build_manifest(test_transcripts, test_manifest, target_wavs_dir)
```

Run processing script.
```
$ preprocess.py 
```

This will create a folder an4_converted in the same directory. 
3. Run the training job 
```
$ cd /shared/nemo_asr/
$ vi asr_finetune.slurm
```

Copy the following contents to the `asr_finetune.slurm`. Make desired changes like no of nodes, devices etc. This script will run for 2 nodes with 8 GPUs each. Also edit no of epochs as desired.  For production run, also remvoe `trainer.fast_dev_run=true`. 

```
#!/bin/bash

#SBATCH -p all
#SBATCH --nodes 2
#SBATCH -t 24:00:00
#SBATCH -J nemo-asr-ft
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8
#SBATCH --exclusive
#SBATCH --overcommit
#SBATCH --open-mode=append

GPFS="/opt/NeMo"

DATA_DIR="/shared/nemo_asr/data"


PROJECT=WANDB_PROJECT # if you want to use wandb

RESULTS_DIR="/shared/nemo_asr/result_dir"

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
&& export DATA_DIR=/shared/nemo_asr/data \
&& python3 /opt/NeMo/examples/asr/speech_to_text_finetune.py \
        --config-path="/opt/NeMo/examples/asr/conf/fastconformer/hybrid_transducer_ctc/" --config-name=fastconformer_hybrid_transducer_ctc_bpe \
        +init_from_pretrained_model=stt_en_fastconformer_hybrid_large_pc \
        ++model.train_ds.manifest_filepath="$DATA_DIR/an4_converted/train_manifest.json" \
        ++model.validation_ds.manifest_filepath="$DATA_DIR/an4_converted/test_manifest.json" \
        ++model.optim.sched.d_model=1024 \
        ++trainer.devices=8 \
        ++trainer.num_nodes=${SLURM_JOB_NUM_NODES} \
        ++trainer.max_epochs=1 \
        ++trainer.precision=bf16 \
        ++model.optim.name="adamw" \
        ++model.optim.lr=0.1 \
        ++model.optim.weight_decay=0.001 \
        ++model.optim.sched.warmup_steps=100 \
        ++exp_manager.version=test \
        ++exp_manager.use_datetime_version=False \
        ++exp_manager.exp_dir=$DATA_DIR/checkpoints \
        ++trainer.fast_dev_run=true
EOF

srun -o $OUTFILE -e $ERRFILE bash -c "${cmd}"
set +x
```
4. Submit the slurm job

```
$ sbatch nemo-llama3-8b-finetune.sh
```

5. Monitor the job
```
$ squeue
```

6. Monitor the log
```
$ cd result_dir
$ cat sft*_0.err
$ cat sft*_0.out
```
 
