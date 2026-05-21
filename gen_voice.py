import asyncio
import edge_tts

async def main():
    # Script for 15-second video - slightly longer and more natural
    script = (
        "大家好，我是千鸟官山，专注土鸡蛋批发。"
        "我们家的土鸡蛋，全部都是散养吃虫吃谷子的纯正土鸡蛋，蛋黄大蛋清浓。"
        "一件也是批发价，不管你在东南西北，我们家全国都可以发货。"
        "需要土鸡蛋的朋友，随时联系我，一件也是批发价。"
    )
    
    print(f"Script length: {len(script)} chars")
    
    # Try Yunyang (mature male, boss vibe) first
    print("Generating Yunyang voice...")
    communicate = edge_tts.Communicate(script, 'zh-CN-YunyangNeural', rate='+0%', pitch='+0Hz')
    await communicate.save(r'C:\Users\Administrator\.openclaw\media\tool-video-generation\tts_yunyang.mp3')
    print("Yunyang saved!")

    # Also try Yunxi (young male) for comparison  
    print("Generating Yunxi voice...")
    communicate = edge_tts.Communicate(script, 'zh-CN-YunxiNeural', rate='+0%', pitch='+0Hz')
    await communicate.save(r'C:\Users\Administrator\.openclaw\media\tool-video-generation\tts_yunxi.mp3')
    print("Yunxi saved!")

    # Check durations
    import subprocess, json
    ffmpeg = r'C:\Users\Administrator\AppData\Local\Programs\Python\Python310\lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe'
    for name in ['tts_yunyang.mp3', 'tts_yunxi.mp3']:
        path = rf'C:\Users\Administrator\.openclaw\media\tool-video-generation\{name}'
        result = subprocess.run([ffmpeg, '-i', path], capture_output=True, text=True)
        for line in result.stderr.split('\n'):
            if 'Duration' in line:
                print(f"{name}: {line.strip()}")

asyncio.run(main())
