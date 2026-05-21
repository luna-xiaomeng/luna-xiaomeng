import paramiko, base64, os, sys

print("Starting download...")
sys.stdout.flush()

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30, banner_timeout=30)
print("Connected")
sys.stdout.flush()

transport = ssh.get_transport()
channel = transport.open_session()
channel.exec_command("cd /root/egg_video && base64 chattts_compressed.mp4")
print("Command sent, reading...")
sys.stdout.flush()

chunks = []
while True:
    chunk = channel.recv(8192)
    if not chunk:
        break
    chunks.append(chunk)

data = b"".join(chunks)
print(f"Got {len(data)} bytes")
sys.stdout.flush()

decoded = base64.b64decode(data)
local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\成品_ChatTTS.mp4"
with open(local, "wb") as f:
    f.write(decoded)

sz = os.path.getsize(local)
print(f"DONE: {sz/1024:.0f}KB")
ssh.close()
