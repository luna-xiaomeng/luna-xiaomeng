import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Upload check script via SFTP
with t.open("/root/egg_video/check_chattts_api.py", "w") as f:
    f.write("""import ChatTTS, inspect
sig = inspect.signature(ChatTTS.Chat.infer)
for n, p in sig.parameters.items():
    default = "REQ" if p.default is inspect.Parameter.empty else str(p.default)
    print(f"  {n}: {default}")
print(f"version: {getattr(ChatTTS, '__version__', 'unknown')}")
""")

t.close()
ssh.close()
print("Uploaded check_chattts_api.py")
