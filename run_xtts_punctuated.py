"""XTTS v2 - with proper punctuation for natural breaks"""
import os
os.chdir('/root/egg_video')
os.environ['COQUI_TOS_AGREED'] = '1'

from TTS.api import TTS
import torchaudio

ref_audio = '/root/egg_video/combined_ref.wav'
output_dir = '/root/egg_video/xtts_output'

target_text = "批发土鸡蛋的老板看过来！我们家做的是纯正散养土鸡蛋，蛋黄大，蛋清浓，口感香。一件也是批发价，全国各地都能发货。有需要的老板留个联系方式。"

print("Loading XTTS v2 model...")
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)

print(f"Target: {target_text}")
output_path = os.path.join(output_dir, 'boss_xtts_punctuated.wav')
tts.tts_to_file(
    text=target_text,
    speaker_wav=ref_audio,
    language="zh-cn",
    file_path=output_path,
)
print(f"Saved: {output_path} ({os.path.getsize(output_path)/1024:.1f}KB)")

# Convert to 16kHz
output_16k = os.path.join(output_dir, 'boss_xtts_punctuated_16k.wav')
waveform, sr = torchaudio.load(output_path)
if waveform.shape[0] > 1:
    waveform = torchaudio.functional.downmix(waveform, waveform.shape[0])
resampled = torchaudio.functional.resample(waveform, sr, 16000)
torchaudio.save(output_16k, resampled, 16000)
print(f"16kHz: {output_16k} ({os.path.getsize(output_16k)/1024:.1f}KB)")

print("DONE!")
