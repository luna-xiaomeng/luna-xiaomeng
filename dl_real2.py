import paramiko, base64, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

transport = ssh.get_transport()
ch = transport.open_session()
ch.exec_command("cd /root/egg_video && base64 final_realistic.mp4")

chunks = []
while True:
    d = ch.recv(8192)
    if not d:
        break
    chunks.append(d)

raw = base64.b64decode(b"".join(chunks))
local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\版本A_真人化.mp4"
with open(local, "wb") as f:
    f.write(raw)
print(f"Done: {os.path.getsize(local)/1024:.0f}KB")
ssh.close()
