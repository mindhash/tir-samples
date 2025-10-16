
chown -R admin pfs

export HF_HOME=/pfs/hf 

huggingface-cli login --token <token>

huggingface-cli download --repo-type model meta-llama/Llama-3.1-8B

We will use this model as tokenizer. Confirm it is available in /pfs/hf/hub/models--meta-llama--Llama-3.1-8B/snapshots/d04e592bb4f6aa9cfee91e2e20afa771667e1d4b
