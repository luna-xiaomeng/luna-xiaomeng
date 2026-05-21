import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=30):
    si, so, se = ssh.exec_command(cmd, timeout=timeout)
    out = "".join(so.readlines())
    err = "".join(se.readlines())
    if out: print(out[-400:])
    if err:
        el = err.strip().split("\n")
        for l in el[-2:]: print(f"  ERR: {l[:100]}")

print("=== File check ===")
run("file /root/egg_video/tts_standard.wav", 10)
run("ffprobe -v error -show_entries format=format_name,duration /root/egg_video/tts_standard.wav 2>&1", 10)

# Now re-merge with standard Mandarin audio
print("\n=== Re-merging ===")
run("""
cd /root/egg_video

# Concat clips
ffmpeg -y -f concat -safe 0 -i clips.txt -c:v libx264 -preset fast -crf 23 -c:a aac merged_temp.mp4 -hide_banner -loglevel error 2>&1

# Speed up audio to fit video if needed (or pad)
AUDIO="tts_standard.wav"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO")
echo "Audio: ${DUR}s"

# Overlay TTS audio
ffmpeg -y -i merged_temp.mp4 -i "$AUDIO" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 192k -shortest \
  final_douyin2.mp4 -hide_banner -loglevel error 2>&1

echo "=== RESULT ==="
ls -la final_douyin2.mp4
""", 120)

ssh.close()
