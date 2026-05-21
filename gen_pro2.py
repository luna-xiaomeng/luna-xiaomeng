import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

# ChatTTS already generated the raw file. Just need to post-process it.
# Also we can generate a new longer one
t = ssh.open_sftp()

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

raw_path = "/root/egg_video/chattts_raw_new.wav"
sf.write(raw_path, wavs[0], 24000)
dur = len(wavs[0]) / 24000
print(f"RAW: {dur:.1f}s")

out_path = "/root/egg_video/chattts_final.wav"

# Correct audio post-processing filter chain
filter_chain = (
    "highpass=f=80,lowpass=f=8000,"      # remove sub-bass rumble and harsh highs
    "acompressor=threshold=0.3:ratio=2:attack=5:release=100,"  # compression
    "volume=2.5,"                          # loudness boost
    "aformat=sample_rates=48000:channel_layouts=mono"           # format
)

cmd = ["ffmpeg", "-y", "-i", raw_path, "-af", filter_chain,
       "-sample_fmt", "s16", out_path, "-hide_banner", "-loglevel", "error"]
subprocess.run(cmd)

sz = os.path.getsize(out_path)
res = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
    "-of", "csv=p=0", out_path], capture_output=True, text=True)
d = res.stdout.strip()
print(f"FINAL: {sz/1024:.0f}KB | {d}s")
print("DONE")
"""

with t.open("/root/egg_video/gen_chattts_final.py", "w") as f:
    f.write(script)

t.close()

# Run
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_chattts_final.py 2>&1", timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

# Now merge with video
print("\nMerging...")
si, so, se = ssh.exec_command("""
cd /root/egg_video
ffmpeg -y -f concat -safe 0 -i clips.txt -c:v libx264 -preset fast -crf 23 merged_nosound.mp4 -hide_banner -loglevel error 2>&1
ffmpeg -y -i merged_nosound.mp4 -i chattts_final.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest final_chattts.mp4 -hide_banner -loglevel error 2>&1
ls -la final_chattts.mp4
""", timeout=120)
out2 = "".join(so.readlines())
err2 = "".join(se.readlines())
if out2: print(out2[-400:])
if err2: print("ERR:", err2[-200:])

ssh.close()
