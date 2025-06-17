# Deploy nvidia riva as TIR endpoint

### Architecture
Riva requires two components: 
(i)  API Server (Middleware) for handling user sessions and speech processing 
(ii) Triton Server for serving the models 

This structure introduces two possible architectural choices. You can package both the components in a single container or run separate containers. From a scale perspective, we recommend separating the two to allow independant scaling.

In this article, we will focus on separate endpoint for Riva API and Triton. 

### Pre-requisites

Riva support a long list of models. To serve them using triton server, we first need to convert them from source format (e.g. nemo, riva, huggingface) to triton engine format. The following steps will require Riva container (Riva:2.19.0 or higher) to perform actions. You can run the container from a  TIR node or a VM (requires same GPU as will be used in production).

1. Launch a TIR Node (TIR >> Nodes >> Create Node) with image [Nvidia Riva](nvcr.io/nvidia/riva/riva-speech:2.19.0) and version `2.19.0`
2. When the node comes to RUNNING state, click on jupyter lab icon to open the notebook. We will perform rest of the model prep from notebook.
3. Open a new terminal
4. Download your model to this TIR node. if you have a custom model and a single file, just drag and drop it to file browser. If not then use scp or other methods.
In this article, we will use a nvidia provided model that comes in .riva format. you can download it from [this link](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/riva/models/parakeet-ctc-riva-0-6b-en-us/files). It requires NGC login/signup.  
5. Now that you have the model downloaded on your local, you can simply drag it to filebrowser in jupyter labs. It might take a while to upload full model. Jupyter labs doesnt show progress bar for larger files, so you may have to just match the file size on your local to what you see in labs file browser to confirm, the model upload is complete. Another method is to enable SSH on the tir node and use scp or rsync to upload this .riva model.

6. 


