import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=600):
    print(f">>> {cmd[:60]}")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out: print(out[-300:])
    if err:
        el = err.strip().split("\n")
        for l in el[-2:]:
            print(f"  ERR: {l}")
    return exit_code

# Download remaining model files from GitHub release
run("""
cd /root/SadTalker/checkpoints

# Download safetensors (for face render)
curl -L --retry 5 -o SadTalker_V0.0.2_256.safetensors 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/SadTalker_V0.0.2_256.safetensors' 2>&1 | tail -3
""", 600)

run("""
cd /root/SadTalker/checkpoints
curl -L --retry 5 -o SadTalker_V0.0.2_512.safetensors 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/SadTalker_V0.0.2_512.safetensors' 2>&1 | tail -3
""", 600)

# Also check what other checkpoints via init_path
run("""
cd /root/SadTalker
grep -oP "checkpoint_dir.*?\.pth" src/utils/init_path.py 2>/dev/null | head -10
""", 10)

# List final checkpoint files
run("ls -la /root/SadTalker/checkpoints/*.pth* 2>/dev/null", 10)

ssh.close()
