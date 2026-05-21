import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Script with refine stage for standard Mandarin
script = """import ChatTTS, torch, soundfile as sf, time, os, sys

# Suppress warnings
import warnings
warnings.filterwarnings("ignore")

torchaudio = __import__("torchaudio")
chat = ChatTTS.Chat()
chat.load(compile=False, source="huggingface")

# Use refine stage to control accent - standard Mandarin
text = (
    "大家好，我是千鸟官山。"
    "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
    "一件也是批发价，全国都可以发货。"
    "需要土鸡蛋的朋友，随时联系我。"
)

# Don't skip refine - use it to add standard Mandarin markers
# Lower temperature for more stable, standard pronunciation
params_infer_code = ChatTTS.core.Chat.InferCodeParams(
    temperature=0.2,
    top_P=0.3,
    top_K=10,
)

wavs = chat.infer(
    text,
    skip_refine_text=False,
    params_infer_code=params_infer_code,
)

out_path = "/root/egg_video/chattts_mandarin.wav"
sf.write(out_path, wavs[0], 24000)
sz = os.path.getsize(out_path)
dur = len(wavs[0]) / 24000
print(f"Saved: {sz/1024:.0f}KB | {dur:.1f}s")
"""

with t.open("/root/egg_video/gen_chattts_mandarin.py", "w") as f:
    f.write(script)

t.close()

# Run it
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_chattts_mandarin.py 2>&1", timeout=300)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-800:])
if err: print("ERR:", err[-250:])

ssh.close()
