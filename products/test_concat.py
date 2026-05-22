"""Simple video concat test"""
import sys, os
sys.stdout.reconfigure(encoding='utf-8')
from moviepy import *

MEDIA = r"C:\Users\Administrator\.openclaw\media"

sp = VideoFileClip(os.path.join(MEDIA, "stock-phone.mp4")).subclipped(0, 5)
sp = sp.resized(height=1920)
if sp.w > 1080:
    sp = sp.cropped(x_center=sp.w/2, width=1080)

print(f"stock_phone: {sp.duration:.1f}s {sp.w}x{sp.h}")
print("Rendering simple concat...")

final = sp
final.write_videofile(
    os.path.join(MEDIA, "..", "workspace", "products", "test.mp4"),
    codec="libx264",
    audio_codec="aac",
    fps=25,
    bitrate="2000k",
    preset="ultrafast",
    logger=None
)
print("DONE!")
sp.close()
