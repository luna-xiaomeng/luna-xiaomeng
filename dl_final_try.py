import paramiko, base64, os

local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\成品视频.mp4"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

# Use cd to change dir, then base64
si, so, se = ssh.exec_command("cd /root/egg_video && base64 compressed_small.mp4", timeout=120)
encoded = "".join(so.readlines())
print(f"Received {len(encoded)} chars")

raw = base64.b64decode(encoded)
with open(local, "wb") as f:
    f.write(raw)

sz = os.path.getsize(local)
print(f"Downloaded: {sz/1024/1024:.2f}MB")
ssh.close()
