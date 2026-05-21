import paramiko, base64, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

transport = ssh.get_transport()

files = [
    ("edge_yunjian.wav", "Edge_Yunjian.wav"),
    ("edge_yunxia.wav", "Edge_Yunxia.wav"),
    ("edge_yunyang.wav", "Edge_Yunyang.wav"),
]

for remote, local in files:
    ch = transport.open_session()
    ch.exec_command(f"cd /root/egg_video && base64 {remote}")
    chunks = []
    while True:
        d = ch.recv(8192)
        if not d: break
        chunks.append(d)
    decoded = base64.b64decode(b"".join(chunks))
    lp = os.path.join(r"C:\Users\Administrator\.openclaw\media\tool-video-generation", local)
    with open(lp, "wb") as f:
        f.write(decoded)
    print(f"{local}: {os.path.getsize(lp)/1024:.0f}KB")

ssh.close()
