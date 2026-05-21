import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Correct filter chain
cmds = """
cd /root/egg_video

# Use a single filter chain (no line breaks)
ffmpeg -y -i edge_yunjian.wav \\
  -af "aecho=0.8:0.5:50:0.4,volume=1.5,aformat=sample_rates=48000:channel_layouts=mono" \\
  yunjian_real.wav -hide_banner -loglevel error 2>&1

echo "AUDIO OK: $(ls -la yunjian_real.wav 2>/dev/null | awk '{print $5}')"

# Merge with video
ffmpeg -y -i merged_nosound.mp4 -i yunjian_real.wav \\
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest \\
  final_realistic.mp4 -hide_banner -loglevel error 2>&1

echo "VIDEO OK: $(ls -la final_realistic.mp4 2>/dev/null | awk '{print $5}')"
"""

si, so, se = ssh.exec_command(cmds, timeout=60)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-400:])
if err: print("ERR:", err[-200:])

ssh.close()
