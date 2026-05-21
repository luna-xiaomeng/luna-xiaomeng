"""Fish Speech voice cloning - Egg Boss"""
import os
os.chdir('/root/egg_video')

from fish_speech.api import TTS
from fish_speech.i18n import i18n
import torchaudio

ref_audio = '/root/egg_video/douyin_voice_raw.wav'
output_dir = '/root/egg_video/fish_output'
os.makedirs(output_dir, exist_ok=True)

target_text = "批发土鸡蛋的老板看过来！我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。一件也是批发价，全国各地都能发货。有需要的老板留个联系方式。"

print("Loading Fish Speech model...")
tts = TTS()

print("Generating with zero-shot voice cloning...")
output = tts.generate(
    text=target_text,
    reference_audio=ref_audio,
    max_new_tokens=1024,
    chunk_length=200,
)

output_path = os.path.join(output_dir, 'boss_fish.wav')
torchaudio.save(output_path, output, 44100)
print(f"Saved: {output_path} ({os.path.getsize(output_path)/1024:.1f}KB)")

# Convert to 16kHz for SadTalker
output_16k = os.path.join(output_dir, 'boss_fish_16k.wav')
resampled = torchaudio.functional.resample(output, 44100, 16000)
torchaudio.save(output_16k, resampled, 16000)
print(f"Saved 16kHz version: {output_16k} ({os.path.getsize(output_16k)/1024:.1f}KB)")

print("DONE!")
