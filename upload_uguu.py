import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Upload to uguu.se from the server
cmds = """
curl -s -F "files[]=@/root/egg_video/compressed.mp4" https://uguu.se/api/upload 2>&1
"""
si, so, se = ssh.exec_command(cmds, timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[:500])
if err: print("ERR:", err[:200])

ssh.close()
