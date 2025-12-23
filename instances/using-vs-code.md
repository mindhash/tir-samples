# Use VS Code with TIR instances 

### Install SSH Extension
In VS Code, Install `Remote - SSH` extension from microsoft. 

<img width="991" height="298" alt="image" src="https://github.com/user-attachments/assets/1bfe37cd-a248-42ec-9f6a-8892c9cdf254" />


### Click on `<>` at bottom left of screen. This is to open a remote window. 

<img width="276" height="101" alt="image" src="https://github.com/user-attachments/assets/a3fbdb0b-b2c8-471c-ac4d-0b8456a5a84d" />

### Enter TIR Instance connection details

Click on Connect to host  
<img width="689" height="311" alt="image" src="https://github.com/user-attachments/assets/bcecf4c7-211a-41cc-a02b-b23616623c47" />

Click Add a New SSH Host 
<img width="586" height="27" alt="image" src="https://github.com/user-attachments/assets/de726b18-babc-4b29-8678-9145937063b8" />

Enter SSH connection info for TIR instance (from UI). Click on icon in SSH Access column to get connection info 
<img width="1102" height="149" alt="image" src="https://github.com/user-attachments/assets/544fbda9-fe5b-4ca6-a211-c042308e073f" />

This will open a new window. 

### Open Folder
Click on open folder and you will notice all directories from /home/jovyan. open the relevant directory or work with /home/jovyan itself.  You can edit files as needed. 
<img width="1352" height="414" alt="image" src="https://github.com/user-attachments/assets/40d45d0f-763f-43ad-ba87-f3ab2560632c" />

### Open terminal 
You can also open terminal in vs code and run commands in TIR instance

<img width="219" height="164" alt="image" src="https://github.com/user-attachments/assets/206acb49-8936-4a32-a224-74aabcf728f4" />

### Running and testing web server
Lets say you are developing a flask API and need to test it. The following steps will allow you to access API server at port 7860. 

In TIR UI, Instances tab >> click on your instance.  In overview seciton, you can find `Add Ons`. Select Configure Addons button.

<img width="1138" height="265" alt="image" src="https://github.com/user-attachments/assets/f9acf5ce-38a6-4178-aa31-779920a9a32f" />

Choose Gradio option
<img width="1136" height="215" alt="image" src="https://github.com/user-attachments/assets/3a7f3d83-d827-4004-9475-70e47bec4206" />

When done, your instance will allow any application running on 7860 to be accessible in browser. 

<img width="538" height="119" alt="image" src="https://github.com/user-attachments/assets/ecd80136-5cd2-4161-91e1-3c3f8504873a" />

The URL will also be displayed in Add ons section. 

For e.g. if an application is running on 7860 port like below
``` python3 -m http.server 7860```
It will be accessble from browser. Please note, you will need be logged in TIR to access this page as it works with TIR authentication. 

<img width="491" height="349" alt="image" src="https://github.com/user-attachments/assets/1f97281f-514e-4107-a93a-7e8846ee6e4d" />








