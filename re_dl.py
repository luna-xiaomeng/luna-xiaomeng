import paramiko, os, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

t = ssh.open_sftp()
local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\final_douyin_final.mp4"

# Clean and re-download
if os.path.exists(local):
    os.remove(local)

# Download in one shot with larger timeout
with t.open("/root/egg_video/final_douyin2.mp4", "rb") as r:
    data = r.read()

with open(local, "wb") as l:
    l.write(data)

t.close()
ssh.close()

sz = os.path.getsize(local)
print(f"Downloaded: {sz/1024/1024:.1f}MB")
print(f"Path: {local}")
