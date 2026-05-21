import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Option 1: Edge TTS Yunjian (most suitable voice for 30+ boss)
# Option 2: ChatTTS with pitch-shift to sound more mature
# Merge both versions with video

cmds = """
cd /root/egg_video

# ===== VERSION A: Edge Yunjian =====
ffmpeg -y -i merged_nosound.mp4 -i edge_yunjian.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest final_yunjian.mp4 -hide_banner -loglevel error 2>&1

# ===== VERSION B: ChatTTS with pitch-shift (lower = more mature) =====
# Use rubberband to lower pitch slightly
ffmpeg -y -i new_script_raw.wav -af "rubberband=pitch=0.9:tempo=1.0" -ar 48000 chattts_deep.wav -hide_banner -loglevel error 2>&1

ffmpeg -y -i merged_nosound.mp4 -i chattts_deep.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest final_deep_chattts.mp4 -hide_banner -loglevel error 2>&1

echo "=== Files ==="
ls -la final_yunjian.mp4 final_deep_chattts.mp4
"""

si, so, se = ssh.exec_command(cmds, timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-400:])
if err: print("ERR:", err[-200:])

ssh.close()
