import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

si, so, se = ssh.exec_command("cd /root/egg_video && python3 check_chattts_api.py 2>&1", timeout=30)
print("".join(so.readlines())[-600:])
err = "".join(se.readlines())
if err: print("ERR:", err[-200:])
ssh.close()
