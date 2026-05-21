import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

sftp = ssh.open_sftp()

# Write correct ChatTTS script - check API first
check_script = """import ChatTTS
import inspect
# Print the infer method signature
print("infer signature:")
sig = inspect.signature(ChatTTS.Chat.infer)
for name, param in sig.parameters.items():
    print(f"  {name}: {param.default if param.default is not inspect.Parameter.empty else 'REQUIRED'}")

# Try importing to see ChatTTS version
print(f"ChatTTS version: {ChatTTS.__version__ if hasattr(ChatTTS, '__version__') else 'unknown'}")
"""

with sftp.open("/root/egg_video/check_chattts_api.py", "w") as f:
    f.write(check_script)

sftp.close()
ssh.close()
print("API check script uploaded")
