# VLLM + Tool Calling

## Create Endpoint
1. Start by navigating to Inference >> Endpoint >> Create Endpoint
2. Choose VLLM Framework
3. Choose `Custom model` option and enter the model name: `mistralai/Mistral-Small-3.1-24B-Instruct-2503`. You may choose any other models that support tool calling. 
<img width="927" alt="image" src="https://github.com/user-attachments/assets/8526e3bd-499f-43bf-b3e2-221c9cfa38fd" />

4. Continue by entering other details like HF token, choice of gpu etc.
5. In LLM Settings, search for `config format` and choose mistral.
<img width="910" alt="image" src="https://github.com/user-attachments/assets/087a0bd3-a77d-416e-b407-0caa0a6430fb" />

6. Choose `Load format` as mistral
<img width="892" alt="image" src="https://github.com/user-attachments/assets/e2756b97-b406-43b6-bdd6-8ff7821d17a5" />

7. In Tokenizer setting, choose tokenizer mode as `mistral`
   <img width="881" alt="image" src="https://github.com/user-attachments/assets/45b9d395-d02c-4c64-991f-6d8eda7e16af" />





