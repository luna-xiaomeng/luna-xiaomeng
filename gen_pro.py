import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# ChatTTS generation + FFmpeg post-processing script
script = """import ChatTTS, torch, soundfile as sf, time, os, subprocess

warnings = __import__("warnings")
warnings.filterwarnings("ignore")

torchaudio = __import__("torchaudio")
chat = ChatTTS.Chat()
chat.load(compile=False, source="huggingface")

text = ("大家好，我是千鸟官山。"
        "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
        "一件也是批发价，全国都可以发货。"
        "需要土鸡蛋的朋友，随时联系我，一件也是批发价。")

params_infer_code = ChatTTS.core.Chat.InferCodeParams(
    temperature=0.3,
    top_P=0.7,
    top_K=20,
)

wavs = chat.infer(text, skip_refine_text=True, params_infer_code=params_infer_code)

raw_path = "/root/egg_video/chattts_raw.wav"
sf.write(raw_path, wavs[0], 24000)
sz = os.path.getsize(raw_path)
dur = len(wavs[0]) / 24000
print(f"RAW: {sz/1024:.0f}KB | {dur:.1f}s")

# FFmpeg post-processing pipeline:
# 1. EQ: boost mids for warmth, cut harsh highs
# 2. Compression: smooth out dynamics
# 3. Reverb: subtle warehouse room sound
# 4. Slight noise floor for realism
out_path = "/root/egg_video/chattts_processed.wav"

cmd = [
    "ffmpeg", "-y", "-i", raw_path,
    "-af",
    "eq=1.2:0.8:0.3:1.0:1.0:1.0,"  # bass boost, warm mids
    "compand=attacks=0.1:decays=0.5:points=-80/-80|-30/-18|-12/-9|-6/-4|0/-2:gain=3,"  # gentle compression
    "afftdn=nf=-25,"  # subtle noise floor reduction then add back
    "volume=1.5",  # loudness boost
    "-ar", "48000",
    "-ac", "1",
    "-sample_fmt", "s16",
    out_path,
    "-hide_banner", "-loglevel", "error",
]
subprocess.run(cmd)

sz2 = os.path.getsize(out_path)
result = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
    "-of", "csv=p=0", out_path], capture_output=True, text=True)
dur2 = result.stdout.strip()
print(f"PROCESSED: {sz2/1024:.0f}KB | {dur2}s")
print("DONE")
"""

with t.open("/root/egg_video/gen_chattts_pro.py", "w") as f:
    f.write(script)

t.close()

# Run
print("Generating ChatTTS with post-processing...")
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_chattts_pro.py 2>&1", timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

# Now merge with video
print("\nMerging with video...")
si, so, se = ssh.exec_command("""
cd /root/egg_video
ffmpeg -y -f concat -safe 0 -i clips.txt -c:v libx264 -preset fast -crf 23 merged_nosound.mp4 -hide_banner -loglevel error 2>&1
ffmpeg -y -i merged_nosound.mp4 -i chattts_processed.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest final_pro.mp4 -hide_banner -loglevel error 2>&1
echo "=== FINAL ==="
ls -la final_pro.mp4
""", timeout=120)
out2 = "".join(so.readlines())
err2 = "".join(se.readlines())
if out2: print(out2[-400:])
if err2: print("ERR:", err2[-200:])

ssh.close()
