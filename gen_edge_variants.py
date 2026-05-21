import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

script = """import asyncio, edge_tts, os, subprocess

async def gen():
    text = "批发土鸡蛋的老板看过来！我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。一件也是批发价，全国各地都能发货。有需要的老板留个联系方式。"
    voices = ["zh-CN-YunjianNeural", "zh-CN-YunxiaNeural", "zh-CN-YunyangNeural"]
    for voice in voices:
        name = voice.split("-")[2].lower().replace("neural", "")
        out = f"/root/egg_video/edge_{name}.wav"
        await edge_tts.Communicate(text, voice, rate="+10%").save(out)
        sz = os.path.getsize(out)
        res = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "csv=p=0", out], capture_output=True, text=True)
        d = res.stdout.strip()
        print(f"{name}: {sz/1024:.0f}KB | {d}s")

asyncio.run(gen())
"""

with t.open("/root/egg_video/gen_edge_variants.py", "w") as f:
    f.write(script)

t.close()

si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_edge_variants.py 2>&1", timeout=120)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

ssh.close()
