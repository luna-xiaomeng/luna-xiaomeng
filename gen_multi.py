import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Generate 3 versions with different seeds to get different voices, pick the most mature
script = """import ChatTTS, torch, soundfile as sf, os, subprocess
import numpy as np

warnings = __import__("warnings")
warnings.filterwarnings("ignore")

chat = ChatTTS.Chat()
chat.load(compile=False, source="huggingface")

text = ("批发土鸡蛋的老板看过来！"
        "我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。"
        "一件也是批发价，全国各地都能发货。"
        "有需要的老板留个联系方式。")

# Generate 3 versions with different seeds
for i in range(3):
    print(f"Generating version {i+1}...")
    
    params_infer_code = ChatTTS.core.Chat.InferCodeParams(
        temperature=0.2 + i*0.1,  # slight variation
        top_P=0.5,
        top_K=15,
    )
    
    # Each call generates different speaker embedding
    wavs = chat.infer(text, skip_refine_text=True, params_infer_code=params_infer_code)
    
    out = f"/root/egg_video/new_v{i+1}.wav"
    sf.write(out, wavs[0], 24000)
    sz = os.path.getsize(out)
    dur = len(wavs[0]) / 24000
    print(f"  V{i+1}: {sz/1024:.0f}KB | {dur:.1f}s")
    
    # Calculate audio features (lower avg freq = deeper voice)
    audio = wavs[0].astype(np.float32)
    # Simple RMS energy
    rms = np.sqrt(np.mean(audio**2))
    print(f"  RMS energy: {rms:.4f}")

print("ALL DONE")
"""

with t.open("/root/egg_video/gen_multiple.py", "w") as f:
    f.write(script)

t.close()

# Run
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_multiple.py 2>&1", timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

ssh.close()
