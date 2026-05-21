import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Compress with lower quality to get under 2MB
si, so, se = ssh.exec_command("""
cd /root/egg_video
ffmpeg -y -i final_douyin2.mp4 -c:v libx264 -preset medium -crf 30 -c:a aac -b:a 96k -vf scale=720:1280 -movflags +faststart compressed_small.mp4 -hide_banner -loglevel error 2>&1
ls -la compressed_small.mp4
""", timeout=60)
print("".join(so.readlines())[:300])
print("".join(se.readlines())[:200])

# Now try base64 of the smaller file
si, so, se = ssh.exec_command("wc -c compressed_small.mp4", timeout=10)
print("".join(so.readlines())[:100])

ssh.close()
