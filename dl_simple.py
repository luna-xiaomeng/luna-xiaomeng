import paramiko, os, sys

local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\成品视频.mp4"
if os.path.exists(local):
    try:
        os.remove(local)
    except:
        pass

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

t = ssh.open_sftp()
f = t.open("/root/egg_video/compressed.mp4", "rb")
data = f.read()
f.close()
t.close()
ssh.close()

with open(local, "wb") as f:
    f.write(data)

sz = os.path.getsize(local)
print(f"OK: {sz} bytes ({sz/1024/1024:.1f}MB)")
