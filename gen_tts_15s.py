import asyncio
import edge_tts
import subprocess

async def main():
    # 15-second script - concise promotional text
    script = (
        "大家好，我是千鸟官山。"
        "我们家的土鸡蛋，散养吃虫吃谷，蛋黄大蛋清浓。"
        "一件也是批发价，全国可发。"
        "需要的朋友随时联系我。"
    )
    
    print(f"Script: {script}")
    print(f"Length: {len(script)} chars")
    
    # Use Yunyang (mature male voice, fits 30+ boss)
    communicate = edge_tts.Communicate(script, "zh-CN-YunyangNeural", rate="+0%", pitch="+0Hz")
    out_path = r"C:\Users\Administrator\.openclaw\media\tool-video-generation\tts_15s.mp3"
    await communicate.save(out_path)
    print(f"Saved to {out_path}")
    
    # Check duration
    ffmpeg = r"C:\Users\Administrator\AppData\Local\Programs\Python\Python310\lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"
    result = subprocess.run([ffmpeg, "-i", out_path], capture_output=True, text=True)
    for line in result.stderr.split("\n"):
        if "Duration" in line:
            print(f"Duration: {line.strip()}")

asyncio.run(main())
