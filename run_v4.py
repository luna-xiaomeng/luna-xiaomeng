import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_chattts_v4.py 2>&1", timeout=300)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-800:])
if err: print("ERR:", err[-250:])

# Also check what we have
si, so, se = ssh.exec_command("ls -la /root/egg_video/chattts*.wav 2>/dev/null || echo none", timeout=10)
print("\nChatTTS files:")
print("".join(so.readlines())[:200])

ssh.close()
