import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("43.153.167.72", username="root", password="EggSeller2025@tx", timeout=10)

t = ssh.open_sftp()

# Write edge-tts generation script
gen_script = """import asyncio, edge_tts, os, subprocess

async def main():
    text = "大家好，我是千鸟官山。我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。一件也是批发价，全国都可以发货。需要土鸡蛋的朋友，随时联系我。"
    
    # Use SSML for more natural pacing
    ssml = (
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">'
        '<voice name="zh-CN-YunyangNeural">'
        '<prosody rate="+8%" pitch="+3Hz">'
        '大家好，我是千鸟官山。'
        '<break time="300ms"/>'
        '我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。'
        '<break time="500ms"/>'
        '一件也是批发价，全国都可以发货。'
        '<break time="400ms"/>'
        '需要土鸡蛋的朋友，随时联系我。'
        '</prosody>'
        '</voice>'
        '</speak>'
    )
    
    communicate = edge_tts.Communicate(ssml, "zh-CN-YunyangNeural")
    out_path = "/root/egg_video/tts_mandarin.mp3"
    await communicate.save(out_path)
    
    sz = os.path.getsize(out_path)
    result = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "csv=p=0", out_path], capture_output=True, text=True)
    dur = result.stdout.strip()
    print(f"Saved: {sz/1024:.0f}KB | Duration: {dur}s")

asyncio.run(main())
"""

with t.open("/root/egg_video/gen_tts_ssml.py", "w") as f:
    f.write(gen_script)

t.close()

# Install edge-tts first
si, so, se = ssh.exec_command("pip3 install edge-tts 2>&1 | tail -3", timeout=60)
print("".join(so.readlines())[:200])

# Run the script
si, so, se = ssh.exec_command("cd /root/egg_video && python3 gen_tts_ssml.py 2>&1", timeout=30)
out = "".join(so.readlines())
err = "".join(se.readlines())
if out: print(out[-500:])
if err: print("ERR:", err[-200:])

ssh.close()
