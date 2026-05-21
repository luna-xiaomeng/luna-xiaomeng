import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

def run(cmd, timeout=120):
    si, so, se = ssh.exec_command(cmd, timeout=timeout)
    out = "".join(so.readlines())
    err = "".join(se.readlines())
    if out: print(out[-500:])
    if err:
        el = err.strip().split("\n")
        for l in el[-3:]:
            print(f"  ERR: {l[:150]}")
    return exit_code if 'exit_code' in dir() else 0

# Step 1: Install edge-tts on the server
print("=== Installing edge-tts ===")
run("pip3 install edge-tts 2>&1 | tail -3", 60)

# Step 2: Try CosyVoice (FunAudioLLM)
print("\n=== Trying CosyVoice install ===")
run("pip3 install cosyvoice 2>&1 | tail -5", 300)

# Step 3: Generate audio with edge-tts Yunyang (standard Mandarin) + SSML for natural feel
print("\n=== Generating Edge TTS with SSML ===")
gen = """
import asyncio, edge_tts, os

async def gen():
    text = (
        "大家好，我是千鸟官山。"
        "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
        "一件也是批发价，全国都可以发货。"
        "需要土鸡蛋的朋友，随时联系我。"
    )
    communicate = edge_tts.Communicate(text, "zh-CN-YunyangNeural", rate="+10%", pitch="+5Hz")
    await communicate.save("/root/egg_video/tts_mandarin.mp3")
    print(f"Size: {os.path.getsize('/root/egg_video/tts_mandarin.mp3')/1024:.0f}KB")
    
    # Check duration
    import subprocess
    result = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "csv=p=0", "/root/egg_video/tts_mandarin.mp3"], capture_output=True, text=True)
    print(f"Duration: {result.stdout.strip()}s")

asyncio.run(gen())
"""
si, so, se = ssh.exec_command(f"python3 -c '{gen}'", timeout=30)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out)
if err: print("ERR:", err[:200])

ssh.close()
