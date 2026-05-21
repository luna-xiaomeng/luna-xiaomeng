"""CosyVoice-300M voice cloning for egg boss voice"""
import os, sys, glob, json

# Point to CosyVoice source
sys.path.insert(0, '/root/CosyVoice')
os.chdir('/root/CosyVoice')

from cosyvoice.cli.cosyvoice import CosyVoice
from cosyvoice.utils.file_utils import load_wav
import torchaudio

model_dir = '/root/iic/CosyVoice-300M'
ref_audio = '/root/egg_video/douyin_voice_raw.wav'
output_dir = '/root/egg_video/cosyvoice_output'
os.makedirs(output_dir, exist_ok=True)

print(f"Loading CosyVoice model from {model_dir}...")
cosyvoice = CosyVoice(model_dir)

print(f"Loading reference audio: {ref_audio}")
prompt_sr = 16000
prompt_text = ""

# The text we want to generate
target_text = "批发土鸡蛋的老板看过来！我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。一件也是批发价，全国各地都能发货。有需要的老板留个联系方式。"

print(f"Generating speech with voice cloning...")
print(f"Target text: {target_text}")

# Zero-shot voice cloning
output = cosyvoice.inference_zero_shot(target_text, ref_audio, prompt_text)

output_path = os.path.join(output_dir, 'boss_cloned_voice.wav')
torchaudio.save(output_path, output['tts_speech'], 22050)
print(f"Saved to: {output_path}")

# Also save as 16kHz for SadTalker
output_16k = os.path.join(output_dir, 'boss_cloned_voice_16k.wav')
resampled = torchaudio.functional.resample(output['tts_speech'], 22050, 16000)
torchaudio.save(output_16k, resampled, 16000)
print(f"Saved 16kHz version to: {output_16k}")

print("Done!")
