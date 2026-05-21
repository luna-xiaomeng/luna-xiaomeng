import paramiko, threading, time, os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Start HTTP server in background thread
def start_http():
    si, so, se = ssh.exec_command("cd /root/egg_video && python3 -m http.server 8888 --bind 0.0.0.0 2>/dev/null", timeout=5)
    # Server runs until killed

t = threading.Thread(target=start_http, daemon=True)
t.start()
time.sleep(2)

# Get server IP
si, so, se = ssh.exec_command("curl -s ifconfig.me", timeout=10)
public_ip = "".join(so.readlines()).strip()
print(f"Server public IP: {public_ip}")

ssh.close()
