import asyncio
import edge_tts

async def list_voices():
    voices = await edge_tts.list_voices()
    # Find Chinese male voices
    male_zh = [v for v in voices if v['Locale'].startswith('zh') and 'Male' in v.get('Gender','')]
    print("=== Chinese Male Voices ===")
    for v in male_zh:
        style = v.get('StyleList') or []
        print(f"{v['ShortName']} - {v['Locale']} - styles: {style}")
    print()
    
    # All Chinese
    all_zh = [v for v in voices if v['Locale'].startswith('zh')]
    print("=== All Chinese Voices ===")
    for v in all_zh:
        style = v.get('StyleList') or []
        demo = v.get('SuggestedCodec') or ''
        print(f"{v['ShortName']} - {v['Gender']} - {demo}")

asyncio.run(list_voices())
