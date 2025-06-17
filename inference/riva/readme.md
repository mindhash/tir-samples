# Deploy nvidia riva as TIR endpoint

### Architecture
Riva requires two components: 
(i)  API Server (Middleware) for handling user sessions and speech processing 
(ii) Triton Server for serving the models 

This structure introduces two possible architectural choices. You can package both the components in a single container or run separate containers. From a scale perspective, we recommend separating the two to allow independant scaling.

In this article, we will focus on separate endpoint for Riva API and Triton. 

### Deployment Steps

Riva support a long list of models. To serve them using triton server, we first need to convert them from source format (e.g. nemo, riva, huggingface) to triton engine format. The following steps will require Riva container (Riva:2.19.0 or higher) to perform actions. You can run the container from a  TIR node or a VM (requires same GPU as will be used in production).

Step 1-7 are required if you have model in .nemo or .riva format. 
If you already have a triton model repository format, then skip to step 8. 

1. Launch a TIR Node (TIR >> Nodes >> Create Node) with image [Nvidia Riva](nvcr.io/nvidia/riva/riva-speech:2.19.0) and version `2.19.0`
2. When the node comes to RUNNING state, click on jupyter lab icon to open the notebook. We will perform rest of the model prep from notebook.
3. Open a new terminal
4. Download your model to this TIR node. if you have a custom model and a single file, just drag and drop it to file browser. If not then use scp or other methods.
In this article, we will use a nvidia provided model that comes in .riva format. you can download it from [this link](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/riva/models/parakeet-ctc-riva-0-6b-en-us/files). It requires NGC login/signup.

If you have a model in .nemo format then follow [these steps](https://github.com/nvidia-riva/nemo2riva/tree/main#export-nemo-models-to-riva-with-nemo2riva) to convert to .riva format 

6. Now that you have the model downloaded on your local, you can simply drag it to filebrowser in jupyter labs. It might take a while to upload full model. Jupyter labs doesnt show progress bar for larger files, so you may have to just match the file size on your local to what you see in labs file browser to confirm, the model upload is complete. Another method is to enable SSH on the tir node and use scp or rsync to upload this .riva model.

7. Edit and run the following command (from terminal) to convert .riva to .rmir format. This intermediate format that further gets converted to triton format.
```
$ export NGC_CLI_API_KEY=nvapi-xxx-set-your-key-here-you-can-get-it-from-nvidia-ngc-registry
$ export NGC_CLI_ORG=set-org-here-you-can-get-it-from-ngc-registry

$ riva-build speech_recognition /home/jovyan/hi-conformer-CTC-L-asr-set-3.0-riva-new-averaged.rmir  /home/jovyan/hi-conformer-CTC-L-asr-set-3.0-riva-new-averaged.riva  --decoder-type triton

```
When the command succeeds, you will find a new archive with .rmir extension in the file browser (jupyter labs)
More options on riva-build can be found [here](https://docs.nvidia.com/deeplearning/riva/user-guide/docs/model-overview.html#riva-deploy)

7. Lets build triton package now.

```
$ riva-deploy  /home/jovyan/hi-conformer-CTC-L-asr-set-3.0-riva-new-averaged.rmir  /home/jovyan/model-repository
```

At the end of this step, you will see a model-repository folder in file browser (jupyter labs)

8. **Create TIR Model Repository**: Go to TIR dashboard and create a new model repository (TIR >> Inference >> Model Repository). After repository is created, you will find steps to load files/archives. We will use minio cli (mc) here but you can choose other options too.  

<img width="1215" alt="image" src="https://github.com/user-attachments/assets/e20d3a76-a32b-4bb7-a610-7987228b2dad" />

If you are working on local, install mc (cli) and run the following commands there. In this case, we will use the same TIR node (as used above) to upload model-repository

```
# The following commands can be found along with secret/access key in TIR model repository section
$ mc alias set riva-models <url> <access-key> <secret-key> 
$ mc cp -r /home/jovyan/model-repository riva-models-dvdsfdsdvdsf/riva-dvdsfdsdvdsf
```

9. **Launch Endpoint**:
   We can now launch a TIR endpoint for triton.
   - Go to TIR >> Inference >> Model Endpoints >> Create Endpoint
   - Choose `Triton` as framework option
   - Select Model Repository created in step 8 in the drop down. **Enter `model-repository` in the model path **
      <img width="905" alt="image" src="https://github.com/user-attachments/assets/6c282cbc-6fc2-41e2-b689-9ca1b077057a" />

  
   - Click Next
   - In Server Runtime, select `Custom` from drop down list. and enter `amole2e/riva-speech:2.19.0` as runtime. 
      <img width="935" alt="image" src="https://github.com/user-attachments/assets/3043a317-0322-40ee-b6dc-cf91279fedb0" />

   - Edit rest of the options as desired and click Next. Choose the right gpu and finish the launch.
   - Wait the endpoint comes to running state and then we are ready to launch Riva API server. 


10. **Launch Riva API Server**:
    - Go to TIR >> Inference >> Model Endpoints >> Create Endpoint
    - Choose `Custom Container` as framework option 

      <img width="421" alt="image" src="https://github.com/user-attachments/assets/1c98fa84-439b-464a-8bb8-fd5a4f27c91e" />

    - Select Skip Model Download and continue
      <img width="903" alt="image" src="https://github.com/user-attachments/assets/103149dc-0366-4e89-bc50-72b3c610f5c4" />

    - Select a CPU plan this time as we have a separate server to handle model execution
       <img width="915" alt="image" src="https://github.com/user-attachments/assets/3875d6d9-343a-434b-b2c0-62aa6f34928a" />
    - Select active and max workers as 1 in next step
    - In container configuration, enter `amole2e/riva-speech:2.19.0` as image. Click HTTP Port checkbox to confirm that we will run this service on 8080 port. Click on Advance Configuration and paste the following command: 
    - Follow rest of the steps with appropriate options and launch the endpoint
    - You can monitor the logs or deployment events and wait for the endpoint to come to running state
    - Once the endpoint is running, we can now test the api with riva client 
      


