"""CosyVoice-300M voice cloning - Egg Boss"""
import sys
sys.path.insert(0, '/root/CosyVoice')
sys.path.insert(0, '/root/CosyVoice/third_party/Matcha-TTS')

from cosyvoice.cli.cosyvoice import CosyVoice
import torchaudio
import os

model_dir = '/root/iic/CosyVoice-300M'
ref_audio = '/root/egg_video/douyin_voice_raw.wav'
# Whisper transcription of the reference audio
prompt_text = "批发鸡蛋的老板看过来，这个批发价让你笑出鸡叫声，我们是源头，只要你需要，我就敢发货，全国发货。"
target_text = "批发土鸡蛋的老板看过来！我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。一件也是批发价，全国各地都能发货。有需要的老板留个联系方式。"

output_dir = '/root/egg_video/cosyvoice_output'
os.makedirs(output_dir, exist_ok=True)

print("Loading CosyVoice model...")
cosyvoice = CosyVoice(model_dir)

print("Generating with zero-shot voice cloning...")
output_path = os.path.join(output_dir, 'boss_cloned.wav')
for result in cosyvoice.inference_zero_shot(target_text, prompt_text, ref_audio):
    torchaudio.save(output_path, result['tts_speech'], cosyvoice.sample_rate)
    print(f"Saved: {output_path} ({os.path.getsize(output_path)/1024:.1f}KB)")

# Convert to 16kHz mono for SadTalker
print("Converting to 16kHz for SadTalker...")
output_16k = os.path.join(output_dir, 'boss_cloned_16k.wav')
waveform, sr = torchaudio.load(output_path)
resampled = torchaudio.functional.resample(waveform, sr, 16000)
torchaudio.save(output_16k, resampled, 16000)
print(f"Saved 16kHz: {output_16k} ({os.path.getsize(output_16k)/1024:.1f}KB)")

print("DONE!")
