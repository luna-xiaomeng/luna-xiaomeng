import paramiko, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=60):
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

# Kill existing installs
run("pkill -9 -f 'pip3 install' 2>/dev/null; pkill -9 -f 'python3 -m pip' 2>/dev/null; echo 'killed old'", 5)
time.sleep(1)

# Use APT PyTorch instead (much faster on Ubuntu)
run("apt-get install -y -qq python3-torch python3-torchvision 2>&1 | tail -3", 120)

# Check torch
run("python3 -c 'import torch; print(f\"OK: torch {torch.__version__}, CUDA: {torch.cuda.is_available()}\")'", 10)

# Install remaining deps
run("pip3 install numpy opencv-python pillow scipy scikit-image librosa soundfile 2>&1 | tail -3", 120)

# Install face tools
run("pip3 install face-alignment facexlib basicsr 2>&1 | tail -3", 120)

# Check everything
run("python3 -c 'import torch,cv2,numpy,librosa; print(\"All imports OK\")'", 10)

ssh.close()
print("\n=== DONE! ===")
