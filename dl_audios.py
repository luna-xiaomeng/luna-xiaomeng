import paramiko, base64, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

transport = ssh.get_transport()

# Download RAW ChatTTS (before processing)
for remote, local_name in [
    ("chattts_raw_new.wav", "ChatTTS_原声.wav"),
    ("chattts_final.wav", "ChatTTS_后期.wav"),
]:
    channel = transport.open_session()
    channel.exec_command(f"cd /root/egg_video && base64 {remote}")
    chunks = []
    while True:
        chunk = channel.recv(8192)
        if not chunk:
            break
        chunks.append(chunk)
    data = b"".join(chunks)
    decoded = base64.b64decode(data)
    local = os.path.join(r"C:\Users\Administrator\.openclaw\media\tool-video-generation", local_name)
    with open(local, "wb") as f:
        f.write(decoded)
    print(f"{local_name}: {os.path.getsize(local)/1024:.0f}KB")

ssh.close()
