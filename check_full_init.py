import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Read full init_path
si, so, se = ssh.exec_command("cat /root/SadTalker/src/utils/init_path.py", timeout=10)
print("".join(so.readlines())[:2000])

# Also check what models exist in the checkpoints dir
si, so, se = ssh.exec_command("ls -la /root/SadTalker/checkpoints/", timeout=10)
print("\n=== files ===")
print("".join(so.readlines()))

ssh.close()
