import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=60):
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out: print(out[-500:])
    if err:
        el = err.strip().split("\n")
        for l in el[-2:]:
            print(f"  ERR: {l}")
    return exit_code

# Read init_path.py to see what checkpoints are needed
run("""
cd /root/SadTalker
grep -r "checkpoint" src/utils/init_path.py 2>/dev/null | head -30
""", 10)

# Also check what other models are in the release
run("""
cd /root/SadTalker/checkpoints
# v0.0.2-rc release has these individual files
curl -sL 'https://api.github.com/repos/OpenTalker/SadTalker/releases/latest' | python3 -c "import sys,json; d=json.load(sys.stdin); [print(a['name'], a['size']) for a in d['assets']]" 2>&1 | head -20
""", 60)

ssh.close()
