import paramiko, os, sys

local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\版本A_真人化.mp4"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=60)

t = ssh.open_sftp()
t.get("/root/egg_video/final_realistic.mp4", local)
t.close()
ssh.close()

sz = os.path.getsize(local)
print(f"OK: {sz/1024:.0f}KB")
