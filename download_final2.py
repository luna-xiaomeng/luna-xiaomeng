import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

# Use SFTP with larger buffer
t = ssh.open_sftp()
# Download with explicit buffer size
with t.open("/root/egg_video/final_video.mp4", "rb") as remote:
    with open(r"C:\Users\Administrator\.openclaw\media\tool-video-generation\final_douyin_video.mp4", "wb") as local:
        data = remote.read()
        local.write(data)

t.close()
ssh.close()

import os
sz = os.path.getsize(r"C:\Users\Administrator\.openclaw\media\tool-video-generation\final_douyin_video.mp4")
print(f"Downloaded: {sz/1024/1024:.1f}MB")
