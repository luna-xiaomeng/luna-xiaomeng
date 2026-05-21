import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Longer script for ~15 seconds
script = """import ChatTTS, torch, soundfile as sf, time, os

torchaudio = __import__("torchaudio")
chat = ChatTTS.Chat()
chat.load(compile=False, source="huggingface")

# Longer text for ~15s
text = ("大家好，我是千鸟官山。"
        "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
        "一件也是批发价，全国都可以发货。"
        "需要土鸡蛋的朋友，随时联系我，一件也是批发价。")

wavs = chat.infer(text, skip_refine_text=True)

out_path = "/root/egg_video/chattts_15s.wav"
sf.write(out_path, wavs[0], 24000)
sz = os.path.getsize(out_path)
dur = len(wavs[0]) / 24000
print(f"Saved: {sz/1024:.0f}KB | {dur:.1f}s")
"""

with t.open("/root/egg_video/gen_chattts_long.py", "w") as f:
    f.write(script)

t.close()

si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_chattts_long.py 2>&1", timeout=300)
out = "".join(so.readlines())
err = "".join(se.readlines())
print(out[-600:] if out else "no out")
if err: print("ERR:", err[-250:])

ssh.close()
