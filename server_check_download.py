import paramiko

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

# Check SadTalker inference.py to see what models it needs
run("head -80 /root/SadTalker/inference.py 2>/dev/null", 10)

# Try the correct release - use the full release structure
run("""
cd /root/SadTalker/checkpoints
# Try downloading from GitHub releases using curl with retry
curl -L --retry 5 --retry-delay 5 -o checkpoints.zip 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2/sadtalker_checkpoints.zip' 2>&1 | tail -5
ls -la checkpoints.zip
""", 300)

ssh.close()
