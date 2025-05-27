# VLLM + Tool Calling

## Create Endpoint for Mistral Tool Parser
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





## Create Endpoint for LLAMA4 Tool Parser
1. In TIR, Navigate to Inference >> Endpoints >> Create Endpoint
2. Choose `custom container`
<img width="1218" alt="image" src="https://github.com/user-attachments/assets/dc485657-7bad-4c44-a4e6-0c3475cce97e" />

3. Enter a desired name and choose `skip model download` option
<img width="1195" alt="image" src="https://github.com/user-attachments/assets/9e726abb-0637-4b44-8720-e0d789caf14e" />

4. Choose 2xH200 as it is minimum for LLAMA4-SCout-14B-16E
5. Continue with Active worker as 1.
6. In Image details section, enter the details below:
- Image: registry.e2enetworks.net/aimle2e/vllm:0.9.0_v1
<img width="933" alt="image" src="https://github.com/user-attachments/assets/48a20947-3d4f-42da-b1c0-d049cd0fb3c2" />

- Advanced Configuration >> Args: ["--model","meta-llama/Llama-4-Scout-17B-16E-Instruct","--port","8080","--tensor-parallel-size","2","--max-model-len","64000","--enable-auto-tool-choice","--tool-call-parser","llama4_pythonic","--chat-template","/vllm-workspace/examples/tool_chat_template_llama4_pythonic.jinja"]

<img width="879" alt="image" src="https://github.com/user-attachments/assets/f98dfba7-d07a-472a-b11d-51851f12b5d4" />

- Click Next, In Environment variables add HF_TOKEN with your huggingface token (that has accesss to LLAMA4 models)
<img width="828" alt="image" src="https://github.com/user-attachments/assets/b5fc6b00-a391-4320-b322-6d1fff519bee" />

7. Launch the inference creation
<img width="920" alt="image" src="https://github.com/user-attachments/assets/293fba09-e42a-4a4e-b77a-e3f08eb2428e" />

8. Wait for the endpoint to come ot running state, once `Running` click on API request to get endpoint URL and token. You can also generate a new token on this screen.
<img width="1199" alt="image" src="https://github.com/user-attachments/assets/102d4693-f99d-4f1e-9ef3-1af1f57b90a7" />


9. Launch a CPU node in TIR or run this test script from a notebook from your local: 

```
from openai import OpenAI
import json

token = "eyJhbGciOiJSUzI1NiIs...." # enter your TIR token here  

client = OpenAI(base_url="https://infer.e2enetworks.net/project/...", api_key=token) # enter your endpoint as base url here. 

def get_weather(location: str, unit: str):
    return f"Getting the weather for {location} in {unit}..."
tool_functions = {"get_weather": get_weather}

tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get the current weather in a given location",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {"type": "string", "description": "City and state, e.g., 'San Francisco, CA'"},
                "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
            },
            "required": ["location", "unit"]
        }
    }
}]

response = client.chat.completions.create(
    model=client.models.list().data[0].id,
    messages=[{"role": "user", "content": "What's the weather like in San Francisco?"}],
    tools=tools,
    tool_choice="auto"
)

tool_call = response.choices[0].message.tool_calls[0].function
print(f"Function called: {tool_call.name}")
print(f"Arguments: {tool_call.arguments}")
print(f"Result: {get_weather(**json.loads(tool_call.arguments))}")
```
