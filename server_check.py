import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=30):
    si, so, se = ssh.exec_command(cmd, timeout=timeout)
    out = "".join(si.readlines() if hasattr(si, 'readlines') else so.readlines())
    # Actually let me use the proper approach
    si.close()
    out = "".join(so.readlines())
    err = "".join(se.readlines())
    print(out[-600:] if out else "no output")
    if err:
        err_lines = err.strip().split("\n")
        for l in err_lines[-3:]:
            print(f"  ERR: {l[:150]}")

# Check checkpoints
print("=== CHECKPOINTS ===")
run("ls -la /root/SadTalker/checkpoints/ 2>/dev/null", 10)

print("\n=== CHATTTS AUDIO ===")
run("ls -la /root/egg_video/chattts.wav 2>/dev/null || ls -la /root/egg_video/chattts* 2>/dev/null", 10)

print("\n=== HF CACHE ===")
run("du -sh /root/.cache/huggingface 2>/dev/null", 10)

print("\n=== DISK ===")
run("df -h / | tail -1", 5)

print("\n=== ACTIVE PROCESSES ===")
run("ps aux | grep -E 'python|pip|curl|wget' | grep -v grep | grep -v miniforge | grep -v open-webui | head -10", 10)

ssh.close()
