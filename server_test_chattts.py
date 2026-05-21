import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=300):
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=timeout)
    stdin.close()
    exit_code = stdout.channel.recv_exit_status()
    out = "".join(stdout.readlines())
    err = "".join(stderr.readlines())
    if out: print(out[-500:])
    if err: 
        el = err.strip().split("\n")
        for l in el[-3:]:
            print(f"  ERR: {l}")
    return exit_code

# Test ChatTTS generation with GPU
run("""
python3 -c '
import ChatTTS
import torch
import soundfile as sf
import numpy as np

torchaudio = __import__("torchaudio")
print("Torchaudio version:", torchaudio.__version__)

chat = ChatTTS.Chat()
chat.load(compile=False)

text = "大家好，我是千鸟官山。我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋。一件也是批发价，全国可以发货。"
params_infer_code = {
    "spk_emb": None,
    "temperature": 0.3,
    "top_P": 0.7,
    "top_K": 20,
}
wavs = chat.infer([text], params_infer_code=params_infer_code)
sf.write("/root/egg_video/chattts_output.wav", wavs[0], 24000)
print("ChatTTS audio saved!")
import os
print("Size:", os.path.getsize("/root/egg_video/chattts_output.wav"), "bytes")
'
""" 2>&1 | tail -15, 120)

ssh.close()
