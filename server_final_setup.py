import paramiko

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

# Fix SadTalker deps - install missing ones, skip tb-nightly
run("pip3 install basicsr facexlib gfpgan 2>&1 | tail -3", 120)

# Install ChatTTS for realistic voice
run("pip3 install ChatTTS 2>&1 | tail -5", 300)

# Install additional audio processing
run("pip3 install soundfile vocos 2>&1 | tail -3", 60)

# Check ChatTTS
run("python3 -c 'import ChatTTS; print(\"ChatTTS OK\")' 2>&1", 10)

# Download SadTalker model checkpoints
cmds = """
cd /root/SadTalker
mkdir -p checkpoints
cd checkpoints
wget -q --show-progress -O mapping_00229-model_dict-General_0.5.pth https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2/mapping_00229-model_dict-General_0.5.pth
wget -q --show-progress -O mapping_00809-model_dict-General_0.5.pth https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2/mapping_00809-model_dict-General_0.5.pth
wget -q --show-progress -O mapping_01649-model_dict-General_0.5.pth https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2/mapping_01649-model_dict-General_0.5.pth
ls -la
"""
run(cmds, 300)

ssh.close()
print("\n=== Phase 5 done ===")
