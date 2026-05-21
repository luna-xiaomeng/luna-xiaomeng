import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=120):
    print(f">>> {cmd[:60]}")
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

# Uninstall wrong torchaudio, install correct one
run("pip3 uninstall -y torchaudio 2>&1 | tail -3", 30)
run("pip3 install torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu124 2>&1 | tail -5", 300)

# Verify
run("python3 -c 'import torchaudio; print(\"OK:\", torchaudio.__version__)'", 10)

# Now run ChatTTS
run("cd /root/egg_video && python3 gen_chattts.py 2>&1 | tail -15", 120)

ssh.close()
