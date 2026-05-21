import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

sftp = ssh.open_sftp()

# Write ChatTTS generation script on server
chattts_script = """import ChatTTS
import torch
import soundfile as sf
import time, os

torchaudio = __import__("torchaudio")
print(f"TorchAudio: {torchaudio.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

start = time.time()
chat = ChatTTS.Chat()
chat.load(compile=False, device="cuda:0")
print(f"Model load: {time.time()-start:.1f}s")

# Script with natural rhythm
text = (
    "大家好，我是千鸟官山。"
    "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
    "一件也是批发价，全国都可以发货。"
    "需要土鸡蛋的朋友，随时联系我。"
)

params_infer_code = {
    "temperature": 0.3,
    "top_P": 0.7,
    "top_K": 20,
}

start = time.time()
wavs = chat.infer([text], params_infer_code=params_infer_code)
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

with sftp.open("/root/egg_video/gen_chattts.py", "w") as f:
    f.write(chattts_script)

# Write SadTalker run script
sadtalker_script = """import sys, os
sys.path.insert(0, "/root/SadTalker")

from src.test_audio2coeff import Audio2Coeff
from src.facerender.animate import AnimateFromCoeff
from src.generate_batch import get_data
from src.generate_facerender_batch import get_facerender_data
from src.utils.init_path import init_path
from src.utils.preprocess import CropAndExtract
import torch, json, yaml
import cv2
import numpy as np
import warnings
warnings.filterwarnings("ignore")

# Load config
with open("/root/SadTalker/config/sadtalker.yaml", "r") as f:
    cfg = yaml.safe_load(f)

device = "cuda:0"
sadtalker_paths = init_path("checkpoints", "/root/SadTalker/checkpoints", "/root/SadTalker", None)

# Preprocess
preprocess_model = CropAndExtract(sadtalker_paths)

# Run inference
from src.generate_batch import get_data
from src.test_audio2coeff import Audio2Coeff

# Audio to coefficients
audio2coeff = Audio2Coeff(sadtalker_paths["audio2coeff"], device)
coeff_path = audio2coeff.generate("/root/egg_video/chattts.wav", "/root/egg_video/", "temp_coeff")

print(f"Coeff path: {coeff_path}")
print("Done!")
"""

with sftp.open("/root/egg_video/run_sadtalker.py", "w") as f:
    f.write(sadtalker_script)

sftp.close()
ssh.close()
print("Scripts uploaded!")
