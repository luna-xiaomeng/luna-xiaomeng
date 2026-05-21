import paramiko, base64, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

# Base64 encode the file on server and decode locally
si, so, se = ssh.exec_command("base64 /root/egg_video/compressed.mp4", timeout=120)
encoded_data = "".join(so.readlines())

print(f"Got {len(encoded_data)} chars of base64 data")

# Decode
raw = base64.b64decode(encoded_data)

local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\成品视频.mp4"
with open(local, "wb") as f:
    f.write(raw)

sz = os.path.getsize(local)
print(f"Downloaded: {sz/1024/1024:.1f}MB")
ssh.close()
