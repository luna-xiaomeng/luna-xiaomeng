import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=30):
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out:
        lines = out.strip().split("\n")
        for l in lines[-8:]:
            print(f"  {l}")
    if err:
        el = err.strip().split("\n")
        for l in el[-3:]:
            print(f"  ERR: {l[:150]}")
    return exit_code

print("=== Checkpoints ===")
run("ls -la /root/SadTalker/checkpoints/ 2>/dev/null", 10)

print("\n=== ChatTTS audio ===")
run("ls -la /root/egg_video/chattts* 2>/dev/null", 10)

print("\n=== HuggingFace cache ===")
run("du -sh /root/.cache/huggingface 2>/dev/null", 10)

print("\n=== Disk ===")
run("df -h / | tail -1", 5)

print("\n=== Python processes ===")
run("ps aux | grep python | grep -v grep | grep -v miniforge | grep -v open-webui | head -5", 10)

print("\n=== CUDA check ===")
run("python3 -c 'import torch; print(f\"CUDA:{torch.cuda.is_available()}, GPUs:{torch.cuda.device_count()}\")'", 10)

ssh.close()
