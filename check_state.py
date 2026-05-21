import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Check server state
si, so, se = ssh.exec_command("cd /root/egg_video && ffprobe -v error -show_entries format=duration -of csv=p=0 tts_standard_15s.wav 2>/dev/null; ls -la tts_standard_15s.wav final_douyin2.mp4 2>/dev/null", timeout=10)
print("".join(so.readlines())[:300])

# Check if merge processes running
si, so, se = ssh.exec_command("ps aux | grep ffmpeg | grep -v grep | head -5", timeout=5)
print("ffmpeg processes:", "".join(so.readlines())[:200])

ssh.close()
