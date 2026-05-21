import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()
t.get("/root/egg_video/final_video.mp4", r"C:\Users\Administrator\.openclaw\media\tool-video-generation\final_douyin_video.mp4")
t.close()
ssh.close()
print("Downloaded!")
