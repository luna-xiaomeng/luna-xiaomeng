import paramiko, os, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.153.167.72', username='root', password='EggSeller2025@tx', timeout=10)

def run(cmd, timeout=120):
    print(f"\n>>> {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    exit_code = stdout.channel.recv_exit_status()
    out = ''.join(stdout.readlines())
    err = ''.join(stderr.readlines())
    if out: print(out[-800:])
    if err: print(f"ERR: {err[-400:]}")
    return exit_code

# Check environment
run("python3 --version")
run("pip3 list 2>/dev/null | grep -i -E 'torch|face|insight|opencv|audio|movie|imageio|ffmpeg'", timeout=30)
run("nvidia-smi --query-gpu=name,memory.total --format=csv,noheader", timeout=15)

# Install system dependencies
run("apt-get update -qq && apt-get install -y -qq ffmpeg git wget unzip 2>&1 | tail -5", timeout=60)

# Clone SadTalker
run("cd /root && rm -rf SadTalker && git clone --depth 1 https://github.com/OpenTalker/SadTalker.git 2>&1 | tail -3", timeout=60)

# Install Python deps
run("cd /root/SadTalker && pip install -r requirements.txt 2>&1 | tail -5", timeout=300)

# Download model checkpoints
run("""
cd /root/SadTalker
mkdir -p checkpoints
cd checkpoints
wget -q --show-progress https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2/sadtalker_checkpoints.zip
unzip -q sadtalker_checkpoints.zip
rm sadtalker_checkpoints.zip
ls -la
""", timeout=120)

run("python3 -c 'import torch; print(\"CUDA:\", torch.cuda.is_available(), \"GPU count:\", torch.cuda.device_count())'", timeout=15)

ssh.close()
print("\n=== Setup complete! ===")
