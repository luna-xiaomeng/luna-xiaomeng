import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()
# Download ChatTTS audio to local
t.get("/root/egg_video/chattts.wav", r"C:\Users\Administrator\.openclaw\media\tool-video-generation\chattts_result.wav")
t.close()
ssh.close()
print("Downloaded!")
