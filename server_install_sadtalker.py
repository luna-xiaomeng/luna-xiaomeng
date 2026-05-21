import paramiko, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=120):
    print(f">>> {cmd[:70]}")
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
        el = err.strip().split("\n")
        for l in el[-3:]:
            print(f"  ERR: {l}")
    return exit_code

# Check SadTalker status
run("ls /root/SadTalker/ 2>/dev/null | head -10", 10)

# Check GPU
run("python3 -c 'import torch; print(f\"CUDA:{torch.cuda.is_available()}, GPU:{torch.cuda.device_count()}\")'", 10)

# Install remaining requirements for SadTalker (if repo exists)
run("cd /root/SadTalker && pip3 install -r requirements.txt 2>&1 | tail -10", 600)

# Check if face detection + others work
run("python3 -c 'import cv2, numpy, scipy, PIL, librosa; print(\"libs OK\")'", 10)

ssh.close()
print("\n=== Phase 4 done ===")
