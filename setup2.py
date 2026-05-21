import paramiko
import sys

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('43.153.167.72', username='root', password='EggSeller2025@tx', timeout=10)

def run(cmd, timeout=120):
    print(f"\n>>> {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = ''.join(stdout.readlines())
    err = ''.join(stderr.readlines())
    if out: print(out[-600:])
    if err: print(f"ERR: {err[-300:]}")
    return exit_code

# Fix pip
run("which pip3 || apt-get install -y python3-pip -qq 2>&1 | tail -3", 30)

# Check SadTalker
run("ls /root/SadTalker/", 10)

# Install requirements
run("cd /root/SadTalker && pip3 install -r requirements.txt 2>&1 | tail -5", 300)

ssh.close()
print("\nDone phase 2!")
