import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Compress video on server
cmds = """
cd /root/egg_video
ffmpeg -y -i final_douyin2.mp4 -c:v libx264 -preset medium -crf 28 -c:a aac -b:a 128k -movflags +faststart compressed.mp4 -hide_banner -loglevel error 2>&1
echo "Compressed:"
ls -la compressed.mp4
"""
si, so, se = ssh.exec_command(cmds, timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-300:])
if err: print("ERR:", err[:200])

ssh.close()
