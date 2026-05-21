import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Upload the two I2V video clips
local_videos = [
    (r"C:\Users\Administrator\.openclaw\media\tool-video-generation\video-1---e7f0264c-6c73-41ad-9487-be45e75f7538.mp4", "/root/egg_video/clip_a.mp4"),
    (r"C:\Users\Administrator\.openclaw\media\tool-video-generation\video-1---94daec4d-0f44-4fd0-9eb2-a82fdb822a71.mp4", "/root/egg_video/clip_b.mp4"),
]
for local, remote in local_videos:
    t.put(local, remote)
    sz = t.stat(remote).st_size
    print(f"Uploaded {remote} ({sz/1024/1024:.0f}MB)")

# Also upload a bash script for merging
merge_script = """#!/bin/bash
# Merge clips with ChatTTS audio
# 1. Create concat file
echo "file clip_a.mp4" > clips.txt
echo "file clip_b.mp4" >> clips.txt

# 2. Concatenate clips
ffmpeg -y -f concat -safe 0 -i clips.txt -c copy merged_clips.mp4 2>/dev/null

# 3. Overlay TTS audio (loop if shorter, trim if longer)
ffmpeg -y -i merged_clips.mp4 -i /root/egg_video/chattts.wav \
  -c:v copy -c:a aac -b:a 192k -shortest \
  /root/egg_video/final_video.mp4 2>/dev/null

echo "Merge complete!"
ls -la /root/egg_video/final_video.mp4
"""

with t.open("/root/egg_video/merge_video.sh", "w") as f:
    f.write(merge_script)

t.close()

# Make script executable
si, so, se = ssh.exec_command("chmod +x /root/egg_video/merge_video.sh", timeout=5)
print("Perm set")

# List all files
si, so, se = ssh.exec_command("ls -la /root/egg_video/", timeout=10)
print("".join(so.readlines())[:300])

ssh.close()
print("Done!")
