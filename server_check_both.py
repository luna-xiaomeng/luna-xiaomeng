import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

cmds = [
    ("ChatTTS output exists?", "ls -la /root/egg_video/chattts.wav 2>/dev/null"),
    ("Pip processes running?", "ps aux | grep -E 'python|pip' | grep -v grep | wc -l"),
    ("SafeTensors downloaded?", "ls /root/SadTalker/checkpoints/*.safetensors 2>/dev/null"),
    ("Checkpoints size", "du -sh /root/SadTalker/checkpoints/ 2>/dev/null"),
    ("Disk space", "df -h / | tail -1"),
]

for label, cmd in cmds:
    si, so, se = ssh.exec_command(cmd, timeout=15)
    out = "".join(so.readlines()).strip()
    err = "".join(se.readlines()).strip()
    print(f"{label}: {out[:200]}")
    if err and "No such file" not in err:
        print(f"  ERR: {err[:100]}")

ssh.close()
