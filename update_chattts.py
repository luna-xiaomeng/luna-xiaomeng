import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

sftp = ssh.open_sftp()

# Fixed ChatTTS script using correct API
chattts_script = """import ChatTTS
import torch
import soundfile as sf
import time, os

torchaudio = __import__("torchaudio")
print(f"TorchAudio: {torchaudio.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

start = time.time()
chat = ChatTTS.Chat()
chat.load(compile=False, source="huggingface")
print(f"Model load: {time.time()-start:.1f}s")

text = (
    "大家好，我是千鸟官山。"
    "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
    "一件也是批发价，全国都可以发货。"
    "需要土鸡蛋的朋友，随时联系我。"
)

# Use the recommended API
params_infer_code = {
    "temperature": 0.3,
    "top_P": 0.7,
    "top_K": 20,
}

start = time.time()
wavs = chat.infer(text, skip_refine=True, params_infer_code=params_infer_code)
print(f"Inference: {time.time()-start:.1f}s")

out_path = "/root/egg_video/chattts.wav"
sf.write(out_path, wavs[0], 24000)
size = os.path.getsize(out_path)
duration = len(wavs[0]) / 24000
print(f"Saved: {out_path}")
print(f"Size: {size/1024:.1f} KB")
print(f"Duration: {duration:.1f}s")
print("ChatTTS generation complete!")
"""

with sftp.open("/root/egg_video/gen_chattts_v2.py", "w") as f:
    f.write(chattts_script)

sftp.close()
ssh.close()
print("Updated script uploaded!")
