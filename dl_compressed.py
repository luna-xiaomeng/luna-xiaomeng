import paramiko, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

t = ssh.open_sftp()
local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\成品视频.mp4"

# Read all at once
with t.open("/root/egg_video/compressed.mp4", "rb") as r:
    data = r.read()

with open(local, "wb") as l:
    l.write(data)

t.close()
ssh.close()

sz = os.path.getsize(local)
print(f"Downloaded: {sz/1024/1024:.1f}MB")
