"""Xiaomeng Douyin Video - Full Version"""
import sys, os
sys.stdout.reconfigure(encoding='utf-8')
from moviepy import *

MEDIA = r"C:\Users\Administrator\.openclaw\media"
WORKSPACE = r"C:\Users\Administrator\.openclaw\workspace"
OUTPUT = os.path.join(WORKSPACE, "products", "xiaomeng-video-final.mp4")

# Paths
stock_phone = os.path.join(MEDIA, "stock-phone.mp4")
stock_robot = os.path.join(MEDIA, "stock-ai-robot.mp4")
recording = os.path.join(WORKSPACE, "products", "broadcast-recording.mp4")
tts_files = [
    os.path.join(MEDIA, "outbound", "voice-1779415671334---bddf34b0-8250-4966-9b65-220a0809cce1.mp3"),
    os.path.join(MEDIA, "outbound", "voice-1779415675625---369820cd-a159-4a84-9cdf-8133998f5cb7.mp3"),
    os.path.join(MEDIA, "outbound", "voice-1779415680210---233e11d2-28d0-4bf8-8bb2-134fa5bfb269.mp3"),
    os.path.join(MEDIA, "outbound", "voice-1779415684964---409c80c1-9e44-45dd-bbd3-faf8ff6e7c04.mp3"),
]

def to_portrait(clip, target_h=1920, target_w=1080):
    """Resize to portrait, center-crop"""
    s = clip.resized(height=target_h)
    if s.w > target_w:
        s = s.cropped(x_center=s.w/2, width=target_w)
    return s

def make_segment(video_path, audio_path):
    """Create a video+audio segment"""
    vid = VideoFileClip(video_path)
    aud = AudioFileClip(audio_path)
    dur = min(vid.duration - 0.05, aud.duration)
    vid = vid.subclipped(0, dur)
    vid = to_portrait(vid)
    vid = vid.with_audio(aud)
    return vid

print("Building segments...")

# 1. Hook - use stock_phone (first 6s)
print("  Segment 1: Hook")
seg1 = make_segment(stock_phone, tts_files[0])
print(f"    {seg1.duration:.1f}s")

# 2. Pain - use stock_phone (next 9s, take from middle)
print("  Segment 2: Pain")
sp_full = VideoFileClip(stock_phone)  # 21s
sp_pain = sp_full.subclipped(6, 6 + 9.7)  # seconds 6-15.7
sp_pain = to_portrait(sp_pain).with_audio(AudioFileClip(tts_files[1]))
print(f"    {sp_pain.duration:.1f}s")

# 3. Solution - user recording
print("  Segment 3: Solution")
seg3 = make_segment(recording, tts_files[2])
print(f"    {seg3.duration:.1f}s")

# 4. Outro - robot
print("  Segment 4: Outro")
seg4 = make_segment(stock_robot, tts_files[3])
print(f"    {seg4.duration:.1f}s")

# Concat
print("Concatenating...")
final = concatenate_videoclips([seg1, sp_pain, seg3, seg4], method="compose")
print(f"Total: {final.duration:.1f}s 1080x1920")

# Render
print(f"Rendering to {OUTPUT}...")
final.write_videofile(OUTPUT, codec="libx264", audio_codec="aac", fps=25, bitrate="4000k", preset="medium", logger=None)
print("DONE!")

# Cleanup
for c in [seg1, sp_pain, seg3, seg4, sp_full, final]:
    c.close()
