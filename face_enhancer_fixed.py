import os
import torch
from tqdm import tqdm
from src.utils.videoio import load_video_to_cv2
import cv2

class GeneratorWithLen(object):
    def __init__(self, gen, length):
        self.gen = gen
        self.length = length
    def __len__(self):
        return self.length
    def __iter__(self):
        return self.gen

def enhancer_list(images, method='gfpgan', bg_upsampler='realesrgan'):
    gen = enhancer_generator_no_len(images, method=method, bg_upsampler=bg_upsampler)
    return list(gen)

def enhancer_generator_with_len(images, method='gfpgan', bg_upsampler='realesrgan'):
    if os.path.isfile(images):
        images = load_video_to_cv2(images)
    gen = enhancer_generator_no_len(images, method=method, bg_upsampler=bg_upsampler)
    gen_with_len = GeneratorWithLen(gen, len(images))
    return gen_with_len

def enhancer_generator_no_len(images, method='gfpgan', bg_upsampler='realesrgan'):
    print('face enhancer....')
    if not isinstance(images, list) and os.path.isfile(images):
        images = load_video_to_cv2(images)

    from gfpgan import GFPGANer

    if method == 'gfpgan':
        arch = 'clean'
        channel_multiplier = 2
        model_name = 'GFPGANv1.4'
        url = 'https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.4.pth'
    elif method == 'RestoreFormer':
        arch = 'RestoreFormer'
        channel_multiplier = 2
        model_name = 'RestoreFormer'
        url = 'https://github.com/TencentARC/GFPGAN/releases/download/v1.3.4/RestoreFormer.pth'
    elif method == 'codeformer':
        arch = 'CodeFormer'
        channel_multiplier = 2
        model_name = 'CodeFormer'
        url = 'https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth'
    else:
        raise ValueError(f'Wrong model version {method}.')

    if bg_upsampler == 'realesrgan':
        if not torch.cuda.is_available():
            import warnings
            warnings.warn('The unoptimized RealESRGAN is slow on CPU. We do not use it.')
            bg_upsampler = None
        else:
            from basicsr.archs.rrdbnet_arch import RRDBNet
            from realesrgan import RealESRGANer
            model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=23, num_grow_ch=32, scale=2)
            bg_upsampler = RealESRGANer(
                scale=2,
                model_path='https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x2plus.pth',
                model=model, tile=400, tile_pad=10, pre_pad=0, half=True)
    else:
        bg_upsampler = None

    model_path = os.path.join('gfpgan/weights', model_name + '.pth')
    if not os.path.isfile(model_path):
        model_path = os.path.join('checkpoints', model_name + '.pth')
    if not os.path.isfile(model_path):
        model_path = url

    restorer = GFPGANer(
        model_path=model_path, upscale=2, arch=arch,
        channel_multiplier=channel_multiplier, bg_upsampler=bg_upsampler)

    for idx in tqdm(range(len(images)), 'Face Enhancer:'):
        img = cv2.cvtColor(images[idx], cv2.COLOR_RGB2BGR)
        cropped_faces, restored_faces, r_img = restorer.enhance(
            img, has_aligned=False, only_center_face=False, paste_back=True)
        r_img = cv2.cvtColor(r_img, cv2.COLOR_BGR2RGB)
        yield r_img
