import paramiko, base64, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=60)

si, so, se = ssh.exec_command("cd /root/egg_video && base64 final_chattts.mp4", timeout=600)
encoded = "".join(so.readlines())
print(f"Got {len(encoded)} chars")

raw = base64.b64decode(encoded)
local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\成品_ChatTTS.mp4"
with open(local, "wb") as f:
    f.write(raw)

sz = os.path.getsize(local)
print(f"Done: {sz} bytes ({sz/1024/1024:.1f}MB)")
ssh.close()
