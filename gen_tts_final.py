import asyncio
import edge_tts
import subprocess
import os

async def main():
    # Script targeting ~15 seconds with Yunyang male voice
    script = (
        "大家好，我是千鸟官山。"
        "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大，蛋清浓。"
        "一件也是批发价，不管你在东南西北，我们家全国都可以发货。"
        "需要土鸡蛋的朋友，随时联系我，一件也是批发价。"
    )
    
    print(f"Script: {script}")
    
    out_path = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\tts_yunyang_final.mp3"
    communicate = edge_tts.Communicate(script, "zh-CN-YunyangNeural", rate="-5%", pitch="+0Hz")
    await communicate.save(out_path)
    print(f"Saved: {out_path}")
    
    ffmpeg = r"C:\Users\Administrator\AppData\Local\Programs\Python\Python310\lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"
    result = subprocess.run([ffmpeg, "-i", out_path], capture_output=True, text=True)
    for line in result.stderr.split("\n"):
        if "Duration" in line:
            print(f"Duration: {line.strip()}")
    
    file_size = os.path.getsize(out_path)
    print(f"Size: {file_size/1024:.1f} KB")

asyncio.run(main())
