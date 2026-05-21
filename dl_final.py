import paramiko, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

t = ssh.open_sftp()
remote_path = "/root/egg_video/final_video.mp4"
local_path = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\final_douyin.mp4"

# Download in chunks
with t.open(remote_path, "rb") as r:
    with open(local_path, "wb") as l:
        while True:
            chunk = r.read(65536)
            if not chunk:
                break
            l.write(chunk)

t.close()
ssh.close()

sz = os.path.getsize(local_path)
print(f"Downloaded: {sz/1024/1024:.1f}MB")
print(f"Path: {local_path}")
