import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Find the actual video files
import subprocess, os
result = subprocess.run(
    r'powershell -Command "Get-ChildItem \'C:\Users\Administrator\.openclaw\media\tool-video-generation\' -Name *.mp4 | Select-Object -Last 2"',
    capture_output=True, text=True, shell=True
)
local_videos = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
print(f"Found videos: {local_videos}")

base = r"C:\Users\Administrator\.openclaw\media\tool-video-generation"
for i, vname in enumerate(local_videos[:2]):
    local = os.path.join(base, vname)
    remote = f"/root/egg_video/clip_{chr(97+i)}.mp4"  # clip_a, clip_b
    t.put(local, remote)
    sz = t.stat(remote).st_size
    print(f"Uploaded clip_{chr(97+i)}: {sz/1024/1024:.0f}MB")

t.close()

# Create merge script
merge = """#!/bin/bash
echo "file clip_a.mp4" > clips.txt
echo "file clip_b.mp4" >> clips.txt

# Concatenate clips
ffmpeg -y -f concat -safe 0 -i clips.txt -c:v libx264 -c:a aac merged_temp.mp4 2>/dev/null

# Find the ChatTTS audio (prefer mandarin, fallback to regular)
if [ -f chattts_mandarin.wav ]; then
    AUDIO="chattts_mandarin.wav"
elif [ -f chattts_15s.wav ]; then
    AUDIO="chattts_15s.wav"
else
    AUDIO="chattts.wav"
fi

echo "Using audio: $AUDIO"

# Get duration
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO")
echo "Audio duration: ${DUR}s"

# Overlay audio onto merged video, trim to audio length
ffmpeg -y -i merged_temp.mp4 -i "$AUDIO" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 192k -shortest \
  /root/egg_video/final_result.mp4 2>/dev/null

ls -la /root/egg_video/final_result.mp4
echo "=== FINAL VIDEO READY ==="
"""

si, so, se = ssh.exec_command(f"cat > /root/egg_video/merge_final.sh << 'SCRIPT'\n{merge}\nSCRIPT\nchmod +x /root/egg_video/merge_final.sh\necho done", timeout=10)
print("".join(so.readlines())[:100])

ssh.close()
print("Upload complete!")
