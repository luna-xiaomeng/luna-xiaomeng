import socket, ssl, os

# SSH exec to send file content via raw TCP
import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

# Use exec to cat the file, but in smaller chunks
channel = ssh.invoke_shell()
time.sleep(1)
channel.send("cat /root/egg_video/compressed.mp4\n")
time.sleep(0.5)

# This won't work for binary. Let me try a different approach entirely.

ssh.close()
