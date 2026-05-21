import paramiko, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=60):
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

# Check download progress
run("ls -la /root/SadTalker/checkpoints/ 2>/dev/null", 10)
run("ps aux | grep curl | grep -v grep", 10)

ssh.close()
