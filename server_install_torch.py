import paramiko, time

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=300):
    print(f">>> {cmd[:60]}")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out: print(out[-300:])
    if err: 
        ev = err.strip().split("\n")
        for l in ev[-3:]:
            print(f"  ERR: {l}")
    return exit_code

# Kill existing
run("pkill -9 -f 'pip3 install' 2>/dev/null", 5)
time.sleep(1)

# Check what's in cache
run("ls /root/.cache/pip/ 2>/dev/null", 5)

# Try installing torch from local cache (no-deps for speed, then check)
run("pip3 install torch --no-index --find-links /root/.cache/pip/ 2>&1 | tail -5", 120)

# If that fails, try pip with retries
run("pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu124 --timeout 120 2>&1 | tail -5", 600)

# Verify
run("python3 -c 'import torch; print(\"OK!\", torch.__version__, \"CUDA:\", torch.cuda.is_available())'", 10)

ssh.close()
print("\n=== Done! ===")
