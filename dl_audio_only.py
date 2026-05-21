import paramiko, base64, os

local = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\tts_standard_单独.wav"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=30)

# Download just the TTS audio
si, so, se = ssh.exec_command("cd /root/egg_video && base64 tts_standard_15s.wav", timeout=300)
encoded = "".join(so.readlines())
print(f"Got {len(encoded)} chars")

raw = base64.b64decode(encoded)
with open(local, "wb") as f:
    f.write(raw)

sz = os.path.getsize(local)
print(f"Downloaded: {sz} bytes ({sz/1024:.0f}KB)")

# Also check the edge-tts voice info
si2, so2, se2 = ssh.exec_command("cd /root/egg_video && python3 -c \"import edge_tts; print([v['ShortName'] for v in __import__('asyncio').run(edge_tts.list_voices()) if 'CN' in v['ShortName'] and 'Male' in v['Gender']])\"", timeout=30)
voices = "".join(so2.readlines()).strip()
print(f"Male CN voices: {voices[:200]}")

ssh.close()
