import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

for cmd in [
    "pip3 list 2>/dev/null | wc -l",
    "ps aux | grep pip | grep -v grep | wc -l",
    "dpkg -l | grep ffmpeg | head -1",
]:
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=10)
    out = "".join(stdout.readlines()).strip()
    err = "".join(stderr.readlines()).strip()
    print(f"[{cmd[:40]}] => {out[:200]}")
    if err:
        print(f"  ERR: {err[:100]}")

# Check if torch is installed
si, so, se = ssh.exec_command("python3 -c 'import torch; print(torch.__version__)'", timeout=10)
torch_out = "".join(so.readlines()).strip()
torch_err = "".join(se.readlines()).strip()
print(f"[torch] => {torch_out[:100]}")
if torch_err:
    print(f"  ERR: {torch_err[:200]}")

ssh.close()
