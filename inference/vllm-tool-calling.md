# VLLM + Tool Calling

## Create Endpoint
1. Start by navigating to Inference >> Endpoint >> Create Endpoint
2. Choose VLLM Framework
3. Choose `Custom model` option and enter the model name: `mistralai/Mistral-Small-3.1-24B-Instruct-2503`. You may choose any other models that support tool calling. 
<img width="927" alt="image" src="https://github.com/user-attachments/assets/8526e3bd-499f-43bf-b3e2-221c9cfa38fd" />

4. Continue by entering other details like HF token, choice of gpu etc.
5. In LLM Settings, search for `config format` and choose mistral.
<img width="910" alt="image" src="https://github.com/user-attachments/assets/087a0bd3-a77d-416e-b407-0caa0a6430fb" />

6. In LLM Settings, Choose `Load format` as mistral
<img width="892" alt="image" src="https://github.com/user-attachments/assets/e2756b97-b406-43b6-bdd6-8ff7821d17a5" />

7. In LLM Settings, choose tool call parser as mistral
   <img width="942" alt="image" src="https://github.com/user-attachments/assets/29513231-2897-462b-8283-7479520d9b17" />

8. In LLM Settings, enable auto tool call
   <img width="919" alt="image" src="https://github.com/user-attachments/assets/18b2be5e-f047-4a79-b3ad-5ddc515a338a" />

9. In Tokenizer setting, choose tokenizer mode as `mistral`
   <img width="881" alt="image" src="https://github.com/user-attachments/assets/45b9d395-d02c-4c64-991f-6d8eda7e16af" />

10. Editing chat template: By default, mistral 3 uses [this](https://github.com/vllm-project/vllm/blob/main/examples/tool_chat_template_mistral3.jinja) chat template but if you want to edit or change it. You can copy the template and paste in text box shown below. 

   <img width="913" alt="image" src="https://github.com/user-attachments/assets/b42ecf35-459c-4514-a8dd-f24cef2760da" />

10. Thats it! follow the further step to deploy endpoint 

11. Once the deployment is running, you can access api endpoint from **API Request** section. If you don't have auth token, you can create a new token in this section (API Request) as well.
    <img width="1216" alt="image" src="https://github.com/user-attachments/assets/ce4b2ac6-22e6-42b0-8f67-27519d472943" />





