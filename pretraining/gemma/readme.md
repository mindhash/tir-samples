# Gemma Pretraining Recipes  

## Gemma 4B Continual Pretraining 
### Pre-requisities
Launch a new training cluster with Slurm-Nemo 25.07 image 

### Convert to Nemo Format 
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

