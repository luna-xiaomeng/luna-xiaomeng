import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Start HTTP server on port 8765 and download via curl
cmds = """
cd /root/egg_video
# Start a quick HTTP server in background
python3 -m http.server 8765 --bind 127.0.0.1 &
HTTP_PID=$!
sleep 1

# Use wget to download via localhost
wget -q -O /tmp/compressed.mp4 http://127.0.0.1:8765/compressed.mp4 2>&1
echo "wget done"

# Check download
ls -la /tmp/compressed.mp4

# Kill HTTP server
kill $HTTP_PID 2>/dev/null
"""
si, so, se = ssh.exec_command(cmds, timeout=60)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-300:])
if err: print("ERR:", err[:200])

# Now download via SFTP but with the small /tmp copy
ssh.close()
