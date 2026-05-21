import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# Process Yunjian audio for more realism
cmds = """
cd /root/egg_video

# Create realistic warehouse-like audio
# 1. Add subtle room reverb (small warehouse/office)
# 2. Add very subtle background ambience 
# 3. Light compression for warmth
# 4. Slight EQ for natural tone

ffmpeg -y -i edge_yunjian.wav \\
  -af "aecho=0.8:0.7:60|120:0.5|0.3," \\
       "volume=1.3," \\
       "aformat=sample_rates=48000:channel_layouts=mono" \\
  yunjian_real.wav -hide_banner -loglevel error 2>&1

echo "Processed audio:"
ls -la yunjian_real.wav

# Merge with video
ffmpeg -y -i merged_nosound.mp4 -i yunjian_real.wav \\
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest \\
  final_realistic.mp4 -hide_banner -loglevel error 2>&1

echo "Final video:"
ls -la final_realistic.mp4
"""

si, so, se = ssh.exec_command(cmds, timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-400:])
if err: print("ERR:", err[-200:])

ssh.close()
