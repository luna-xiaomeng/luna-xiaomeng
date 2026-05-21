import paramiko, sys, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=300):
    print(f"\n>>> {cmd[:80]}...")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out: print(out[-400:])
    if err: print(f"ERR: {err[-200:]}")
    return exit_code

# Kill existing pip
run("pkill -f 'pip3 install' 2>/dev/null; echo done", 5)
time.sleep(2)

# Step 1: Install core deps
run("pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 2>&1 | tail -3", 600)

# Step 2: Install ML deps
run("pip3 install numpy opencv-python pillow scipy scikit-image 2>&1 | tail -3", 120)

# Step 3: Audio + face alignment
run("pip3 install librosa soundfile face-alignment facexlib basicsr 2>&1 | tail -3", 120)

# Step 4: Check SadTalker
run("ls /root/SadTalker/ 2>/dev/null", 10)

# Step 5: Check GPU
run('python3 -c "import torch; t=torch.cuda.is_available(); print(f\"CUDA: {t}\"); print(f\"GPUs: {torch.cuda.device_count()}\")', 15)

ssh.close()
print("\n=== Server install done! ===")
