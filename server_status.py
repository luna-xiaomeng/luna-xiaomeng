import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

for cmd in [
    "ls -la /root/egg_video/ 2>/dev/null | head -10",
    "df -h / | tail -1",
    "pip3 list 2>/dev/null | wc -l",
    "ps aux | grep -E 'pip|wget' | grep -v grep | head -5",
    "ls -la /root/egg_video/boss.png 2>/dev/null",
    "python3 -c 'import torch; print(\"OK:\", torch.__version__)' 2>&1 | head -1",
]:
    si, so, se = ssh.exec_command(cmd, timeout=10)
    out = "".join(so.readlines()).strip()
    err = "".join(se.readlines()).strip()
    print(f"[{cmd[:40]}]\n{out[:200]}")
    if err:
        print(f"  ERR: {err[:150]}")

ssh.close()
