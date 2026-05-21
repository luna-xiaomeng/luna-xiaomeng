import paramiko, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()
base = r"C:\Users\Administrator\.openclaw\media\tool-video-generation"

files = [
    ("video-1---b38954f1-d749-4449-8181-e5d00948c381.mp4", "clip_a.mp4"),
    ("video-1---fe2116f4-4e39-4cd3-8beb-c35e408f765d.mp4", "clip_b.mp4"),
]

for local_name, remote_name in files:
    local = os.path.join(base, local_name)
    remote = f"/root/egg_video/{remote_name}"
    if os.path.exists(local):
        t.put(local, remote)
        sz = t.stat(remote).st_size
        print(f"Uploaded {remote_name}: {sz/1024/1024:.0f}MB")
    else:
        print(f"NOT FOUND: {local}")

t.close()
ssh.close()
print("Done!")
