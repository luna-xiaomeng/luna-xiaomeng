import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Generate a longer ~15s script
script = """import asyncio, edge_tts, os, subprocess

async def main():
    # Longer script for ~15s
    text = ("大家好，我是千鸟官山。"
            "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
            "一件也是批发价，不管你在哪里，全国都可以发货。"
            "需要土鸡蛋的朋友随时联系我，一件也是批发价。")
    
    communicate = edge_tts.Communicate(text, "zh-CN-YunyangNeural", rate="+10%")
    out_path = "/root/egg_video/tts_standard_15s.wav"
    await communicate.save(out_path)
    sz = os.path.getsize(out_path)
    result = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "csv=p=0", out_path], capture_output=True, text=True)
    dur = result.stdout.strip()
    print(f"Saved: {sz/1024:.0f}KB | Duration: {dur}s")

asyncio.run(main())
"""

with t.open("/root/egg_video/gen_standard_15s.py", "w") as f:
    f.write(script)

t.close()

# Run
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_standard_15s.py 2>&1", timeout=60)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

# Re-merge with correct audio
print("\n=== Merging with 15s audio ===")
si, so, se = ssh.exec_command("""
cd /root/egg_video
ffmpeg -y -f concat -safe 0 -i clips.txt -c:v libx264 -preset fast -crf 23 -c:a aac merged_temp.mp4 -hide_banner -loglevel error
ffmpeg -y -i merged_temp.mp4 -i tts_standard_15s.wav -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k -shortest final_douyin2.mp4 -hide_banner -loglevel error 2>&1
ls -la final_douyin2.mp4
""", timeout=120)
out2 = "".join(so.readlines())
err2 = "".join(se.readlines())
print(out2[-400:] if out2 else "done")
if err2: print("ERR:", err2[-200:])

# Download the final video
import os as pyos
with ssh.open_sftp() as sftp:
    sftp.get("/root/egg_video/final_douyin2.mp4", r"C:\Users\Administrator\.openclaw\media\tool-video-generation\final_douyin_final.mp4")
sz2 = pyos.path.getsize(r"C:\Users\Administrator\.openclaw\media\tool-video-generation\final_douyin_final.mp4")
print(f"\nDownloaded: {sz2/1024/1024:.1f}MB")

ssh.close()
