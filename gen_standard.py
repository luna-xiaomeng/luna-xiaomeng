import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Clean, simple script - Edge TTS Yunyang, standard Mandarin
script = """import asyncio, edge_tts, os, subprocess

async def main():
    text = "大家好，我是千鸟官山。我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。一件也是批发价，全国都可以发货。需要土鸡蛋的朋友，随时联系我。"
    communicate = edge_tts.Communicate(text, "zh-CN-YunyangNeural", rate="+15%")
    out_path = "/root/egg_video/tts_standard.wav"
    await communicate.save(out_path)
    sz = os.path.getsize(out_path)
    result = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "csv=p=0", out_path], capture_output=True, text=True)
    dur = result.stdout.strip()
    print(f"Saved: {sz/1024:.0f}KB | Duration: {dur}s")

asyncio.run(main())
"""

with t.open("/root/egg_video/gen_standard.py", "w") as f:
    f.write(script)

t.close()

# Run
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_standard.py 2>&1", timeout=60)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

ssh.close()
