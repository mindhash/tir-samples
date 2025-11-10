
1. In Inference >> Endpoints >> Create a New Endpoint

2. Select Custom Container option 

<img width="396" height="335" alt="image" src="https://github.com/user-attachments/assets/3ec8c95b-5128-410d-8534-cda6c48cf046" />

3. Choose Skip Model Repository. And Add Model Path `/data` and appropriate disk space. This will be used by redis to store persistent data.

<img width="911" height="517" alt="image" src="https://github.com/user-attachments/assets/a6958f39-01aa-4920-bdce-6bded39da691" />

4. Choose a CPU plan as desired 
<img width="926" height="595" alt="image" src="https://github.com/user-attachments/assets/23514390-e50d-4a23-a7fe-1ca26980d61b" />

5. Enter Image as `redis:7.2`
<img width="918" height="568" alt="image" src="https://github.com/user-attachments/assets/ba974bb5-14fd-4c37-8064-23534b6f533f" />

6. Enter Advance Configuration commands
   <img width="848" height="470" alt="Screenshot 2025-11-10 at 12 14 17" src="https://github.com/user-attachments/assets/7ca2fcbe-340e-4dd0-826b-164bb5e6e6e8" />

7. Enable Readiness Probe
<img width="875" height="362" alt="image" src="https://github.com/user-attachments/assets/eabe7f48-ee30-410f-a776-5bfd0882c061" />

8. Enable Liveness Probe 
<img width="871" height="365" alt="image" src="https://github.com/user-attachments/assets/9455d2fa-6a7d-48b5-ac53-028e74da56b3" />


9. Launch
<img width="924" height="562" alt="image" src="https://github.com/user-attachments/assets/0589e1da-154d-4ad7-b472-84f38a7aa6bf" />


Once done, please reach out to TIR Support team to disable public access (HTTP) and enable local port access in namespace. This is a temporary solution, the feature to run redis with one-click launch will be available soon. 
To acces redis:-
1. install redis client
   ```
   pip install redis
   ```
2. Access it using private client(only accessible in same project)
   ```
   import redis
   r = redis.Redis(
       host='private-endpoint',  eg: is-1234
       port=80,
       decode_responses=True
   )
   r.set("greeting", "hello from python in k8s")
   value = r.get("greeting")
   print("Stored value:", value)
   ```

