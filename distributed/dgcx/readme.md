
chown -R admin pfs

export HF_HOME=/pfs/hf 

huggingface-cli login --token <token>
huggingface-cli download --repo-type model meta-llama/Llama-3.1-8B
