import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Download the ChatTTS audio to check
t = ssh.open_sftp()
t.get("/root/egg_video/chattts_15s.wav", r"C:\Users\Administrator\.openclaw\media\tool-video-generation\chattts_15s_check.wav")
t.close()

# Also check file on server
si, so, se = ssh.exec_command("ls -la /root/egg_video/*.wav", timeout=10)
print("WAV files:")
print("".join(so.readlines()))

ssh.close()
print("Downloaded for quality check")
