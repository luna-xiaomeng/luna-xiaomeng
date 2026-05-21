import paramiko, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=30):
    print(f">>> {cmd[:80]}")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out: print(out[-300:])
    if err: print(f"ERR: {err[-200:]}")
    return exit_code

# Kill existing install processes
run("pkill -9 -f 'pip3' 2>/dev/null; pkill -9 -f 'apt-get' 2>/dev/null; sleep 1; echo killed", 5)

# Create working directory  
run("mkdir -p /root/egg_video", 5)

# Check what we have
run("which ffmpeg python3", 5)

# Upload the boss photo via SCP-like approach
import subprocess, base64

ffmpeg_path = r"C:\Users\Administrator\AppData\Local\Programs\Python\Python310\lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"

# Upload files using sftp
with ssh.open_sftp() as sftp:
    # Upload boss photo
    sftp.put(r"C:\Users\Administrator\.openclaw\media\inbound\老板照片---3baf070e-f277-44c1-a249-edfa1bad11b1.png", "/root/egg_video/boss.png")
    print("Uploaded boss.png")
    
    # Upload TTS audio
    sftp.put(r"C:\Users\Administrator\.openclaw\media\tool-video-generation\tts_15s_final.mp3", "/root/egg_video/tts.mp3")
    print("Uploaded tts.mp3")

    # List files
    for f in sftp.listdir("/root/egg_video/"):
        print(f"  {f}")

print("\n=== Files uploaded! ===")
ssh.close()
