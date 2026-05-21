"""XTTS v2 voice cloning - Egg Boss"""
import os, sys
os.chdir('/root/egg_video')
os.environ['COQUI_TOS_AGREED'] = '1'

from TTS.api import TTS
import torchaudio

ref_audio = '/root/egg_video/douyin_voice_raw.wav'
output_dir = '/root/egg_video/xtts_output'
os.makedirs(output_dir, exist_ok=True)

target_text = "批发土鸡蛋的老板看过来！我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。一件也是批发价，全国各地都能发货。有需要的老板留个联系方式。"

print("Loading XTTS v2 model...")
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)

print("Cloning voice and generating speech...")
output_path = os.path.join(output_dir, 'boss_xtts.wav')
tts.tts_to_file(
    text=target_text,
    speaker_wav=ref_audio,
    language="zh-cn",
    file_path=output_path,
)

print(f"Saved: {output_path} ({os.path.getsize(output_path)/1024:.1f}KB)")

# Convert to 16kHz mono for SadTalker
output_16k = os.path.join(output_dir, 'boss_xtts_16k.wav')
waveform, sr = torchaudio.load(output_path)
# If stereo, mix to mono
if waveform.shape[0] > 1:
    waveform = torchaudio.functional.downmix(waveform, waveform.shape[0])
resampled = torchaudio.functional.resample(waveform, sr, 16000)
torchaudio.save(output_16k, resampled, 16000)
print(f"Saved 16kHz mono: {output_16k} ({os.path.getsize(output_16k)/1024:.1f}KB)")

print("DONE!")
