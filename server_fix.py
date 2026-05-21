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

# Fix torchaudio: install matching version  
run("pip3 install torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu124 2>&1 | tail -3", 300)

# Remove empty checkpoints and download from zip
cmds = """
cd /root/SadTalker/checkpoints
rm -f *.pth
wget -q --show-progress --timeout=60 https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/sadtalker_checkpoints.zip -O checkpoints.zip
ls -la checkpoints.zip
unzip -o checkpoints.zip 2>&1 | tail -5
rm -f checkpoints.zip
ls -la *.pth
"""
run(cmds, 300)

ssh.close()
print("\n=== Phase 6 done ===")
