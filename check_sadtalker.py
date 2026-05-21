import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

si, so, se = ssh.exec_command("grep -n 'checkpoint' /root/SadTalker/src/utils/init_path.py 2>/dev/null | head -20", timeout=10)
print("=== Required checkpoints ===")
print("".join(so.readlines())[:500])

# Also check inference.py to see what it needs
si, so, se = ssh.exec_command("head -100 /root/SadTalker/inference.py 2>/dev/null", timeout=10)
print("\n=== Inference.py header ===")
print("".join(so.readlines())[:500])

ssh.close()
