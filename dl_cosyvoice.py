from modelscope.hub.snapshot_download import snapshot_download
model_dir = snapshot_download("iic/CosyVoice-300M", cache_dir="/root/")
print("Downloaded to:", model_dir)
import os, glob
files = glob.glob(os.path.join(model_dir, "**/*"), recursive=True)
print(f"Total files: {len(files)}")
total_size = sum(os.path.getsize(f) for f in files if os.path.isfile(f))
print(f"Total size: {total_size/1024/1024:.1f} MB")
for f in sorted(files)[:30]:
    if os.path.isfile(f):
        size_mb = os.path.getsize(f)/1024/1024
        print(f"  {f} ({size_mb:.1f}MB)")
