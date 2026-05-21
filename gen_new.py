import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

script = """import ChatTTS, torch, soundfile as sf, os, subprocess

warnings = __import__("warnings")
warnings.filterwarnings("ignore")

chat = ChatTTS.Chat()
chat.load(compile=False, source="huggingface")

text = ("批发土鸡蛋的老板看过来！"
        "我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。"
        "一件也是批发价，全国各地都能发货。"
        "有需要的老板留个联系方式。")

params_infer_code = ChatTTS.core.Chat.InferCodeParams(
    temperature=0.3,
    top_P=0.7,
    top_K=20,
)

wavs = chat.infer(text, skip_refine_text=True, params_infer_code=params_infer_code)

raw_path = "/root/egg_video/new_script_raw.wav"
sf.write(raw_path, wavs[0], 24000)
sz = os.path.getsize(raw_path)
dur = len(wavs[0]) / 24000
print(f"RAW: {sz/1024:.0f}KB | {dur:.1f}s")

# Minimal processing: just volume boost + format conversion
out_path = "/root/egg_video/new_script_final.wav"
cmd = ["ffmpeg", "-y", "-i", raw_path,
       "-af", "volume=2.0,aformat=sample_rates=48000:channel_layouts=mono",
       "-sample_fmt", "s16", out_path,
       "-hide_banner", "-loglevel", "error"]
subprocess.run(cmd)

sz2 = os.path.getsize(out_path)
res = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
    "-of", "csv=p=0", out_path], capture_output=True, text=True)
d2 = res.stdout.strip()
print(f"FINAL: {sz2/1024:.0f}KB | {d2}s")
print("DONE")
"""

with t.open("/root/egg_video/gen_new_script.py", "w") as f:
    f.write(script)

t.close()

# Run
print("Generating new script ChatTTS...")
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_new_script.py 2>&1", timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

# Merge with video
print("\nMerging with video...")
si, so, se = ssh.exec_command("""
cd /root/egg_video
ffmpeg -y -f concat -safe 0 -i clips.txt -c:v libx264 -preset fast -crf 23 merged_nosound.mp4 -hide_banner -loglevel error 2>&1
ffmpeg -y -i merged_nosound.mp4 -i new_script_final.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest final_v3.mp4 -hide_banner -loglevel error 2>&1
ls -la final_v3.mp4
""", timeout=120)
out2 = "".join(so.readlines())
err2 = "".join(se.readlines())
if out2: print(out2[-400:])
if err2: print("ERR:", err2[-200:])

# Also compress for download
si, so, se = ssh.exec_command("""
cd /root/egg_video && ffmpeg -y -i final_v3.mp4 -c:v libx264 -preset fast -crf 28 -c:a aac -b:a 96k -vf scale=720:1280 -movflags +faststart v3_compressed.mp4 -hide_banner -loglevel error 2>&1
ls -la v3_compressed.mp4
""", timeout=60)
out3 = "".join(so.readlines())
err3 = "".join(se.readlines())
if out3: print(out3[-200:])
if err3: print("ERR:", err3[-200:])

ssh.close()
