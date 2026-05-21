import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=60):
    si, so, se = ssh.exec_command(cmd, timeout=timeout)
    out = "".join(so.readlines())
    err = "".join(se.readlines())
    if out: print(out[-500:])
    if err:
        el = err.strip().split("\n")
        for l in el[-3:]:
            print(f"  ERR: {l[:150]}")
    return out

# Check files on server
print("=== Files on server ===")
run("ls -la /root/egg_video/*.mp4 /root/egg_video/*.wav /root/egg_video/*.mp3 2>/dev/null", 10)

# Run merge
print("\n=== Merging video ===")
run("""
cd /root/egg_video

# Create concat list
echo "file clip_a.mp4" > clips.txt
echo "file clip_b.mp4" >> clips.txt

# Concat clips
ffmpeg -y -f concat -safe 0 -i clips.txt -c:v libx264 -preset fast -crf 23 -c:a aac merged_temp.mp4 2>&1 | tail -3

# Overlay Mandarin audio
AUDIO="chattts_mandarin.wav"
if [ ! -f "$AUDIO" ]; then
    AUDIO="chattts_15s.wav"
fi
echo "Using: $AUDIO"

ffmpeg -y -i merged_temp.mp4 -i "$AUDIO" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 192k -shortest \
  final_video.mp4 2>&1 | tail -3

echo "=== RESULT ==="
ls -la final_video.mp4
""", 120)

ssh.close()
