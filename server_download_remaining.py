import paramiko

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
    if out:
        print(out[-300:])
    if err:
        el = err.strip().split("\n")
        for l in el[-2:]:
            print(f"  ERR: {l}")
    return exit_code

# Clean and re-download the two failed files
run("""
cd /root/SadTalker/checkpoints
rm -f mapping_00809* mapping_01649*
wget -O mapping_00809-model.pth.tar 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_00809-model.pth.tar' 2>&1 | tail -3
""", 600)

run("""
cd /root/SadTalker/checkpoints
wget -O mapping_01649-model.pth.tar 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_01649-model.pth.tar' 2>&1 | tail -3
""", 600)

# Check all files
run("ls -la /root/SadTalker/checkpoints/*.tar", 10)

ssh.close()
