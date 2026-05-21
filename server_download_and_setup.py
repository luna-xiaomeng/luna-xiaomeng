import paramiko, os, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=120):
    print(f"\n>>> {cmd[:70]}")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out:
        lines = out.strip().split("\n")
        for l in lines[-5:]:
            print(f"  {l}")
    if err:
        err_lines = err.strip().split("\n")
        for l in err_lines[-3:]:
            print(f"  ERR: {l}")
    return exit_code

# Kill previous processes
run("pkill -9 -f pip3 2>/dev/null; sleep 1", 5)

# Download boss photo from public URL
run("wget -q 'https://d.uguu.se/SNgFgquM.png' -O /root/egg_video/boss.png 2>&1; ls -la /root/egg_video/boss.png", 30)

# Upload TTS files via SFTP
with ssh.open_sftp() as sftp:
    tts_dir = r"C:\Users\Administrator\.openclaw\media\tool-video-generation"
    sftp.put(os.path.join(tts_dir, "tts_15s_final.mp3"), "/root/egg_video/tts.mp3")
    print("Uploaded tts.mp3")
    sftp.put(os.path.join(tts_dir, "tts_yunyang_final.mp3"), "/root/egg_video/tts_full.mp3")
    print("Uploaded tts_full.mp3")

# Check files
run("ls -la /root/egg_video/", 5)

# Now install PyTorch using pip with mirror
run("pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu124 2>&1 | tail -5", 600)

ssh.close()
print("\n=== Phase 3 done ===")
