import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=300):
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

# Clean and download individual checkpoint files (more reliable than zip)
run("""
cd /root/SadTalker/checkpoints
rm -f *.pth *.zip *.tar

# Download mapping models directly via curl with L flag for redirects
curl -L --retry 5 -o mapping_00109-model.pth.tar 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_00109-model.pth.tar' &
curl -L --retry 5 -o mapping_00229-model.pth.tar 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_00229-model.pth.tar' &
curl -L --retry 5 -o mapping_00809-model.pth.tar 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_00809-model.pth.tar' &
curl -L --retry 5 -o mapping_01649-model.pth.tar 'https://github.com/OpenTalker/SadTalker/releases/download/v0.0.2-rc/mapping_01649-model.pth.tar' &

echo "Downloads started in background"
echo "Waiting..."
wait
echo "All downloads complete!"
ls -la
""", 600)

ssh.close()
print("\n=== Downloads done ===")
