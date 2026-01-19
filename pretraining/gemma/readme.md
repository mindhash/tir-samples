# Gemma Pretraining Recipes  

## Gemma 4B Continual Pretraining 
### Pre-requisities
Launch a new training cluster with Slurm-Nemo 25.07 image 

### Convert to Nemo Format 
Set HF tokeb first:
```
$ huggingface-cli login --token <TOKEN_HERE>

# Following assumes you have mounted PFS (Parallel File system) or SFS on /pfs location.  It will set HF Cache to a common folder on shared directory. 
$ export HF_HOME=/pfs/hf

# following will set nemo hub such that converted nemo checkpoints will be stored in this directory 
$ export NEMO_CACHE_HOME=/pfs/nemo_hub
```


Run the following script to convert **Gemma-4b-pt** to Nemo format. 

```
from nemo.collections import llm

if __name__ == '__main__':
    # Specify the Hugging Face model ID (e.g., Gemma3 1B Instruct Model)
    hf_model_id = 'google/gemma-3-4b-pt'
    # Import the model and convert to NeMo 2.0 format
    llm.import_ckpt(
        model=llm.Gemma3Model(config=llm.Gemma3Config4B()),
        source=f"hf://{hf_model_id}",
    )
```


### Copy training scripts
Copy the two scripts (`gemma3_pretrain.py` and `pretrain_gemma3.sh`) to `/pfs/pretraining` directory. The script is set for continual pretraining. So it will allow progress from current base model `gemma3-4b-pt`. 

Please note you may have to find and set the correct IB devices by running in pretrain_gemma3.sh using the following command. 
```
$ ibv_devinfo | sed -n -e '/hca_id/p' -e '/link_layer:/p' | grep -B1 InfiniBand | grep hca_id | sed -e 's/^hca_id://g' | tr -d '[[:blank:]]' | sed 's/$/:1/' | paste -sd ","
```




