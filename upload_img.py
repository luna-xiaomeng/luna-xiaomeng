import requests
import json
import os

# Read the image file
img_path = r'C:\Users\Administrator\.openclaw\media\inbound\老板照片---3baf070e-f277-44c1-a249-edfa1bad11b1.png'

# Try uploading via img.vvw.io (free image hosting)
try:
    with open(img_path, 'rb') as f:
        files = {'file': ('boss.png', f, 'image/png')}
        resp = requests.post('https://tmpfiles.org/api/v1/upload', files=files, timeout=30)
        print('tmpfiles:', resp.status_code, resp.text[:500])
except Exception as e:
    print(f'tmpfiles failed: {e}')

# Try catbox.moe
try:
    with open(img_path, 'rb') as f:
        resp = requests.post('https://catbox.moe/user/api.php', 
            data={'reqtype': 'fileupload'},
            files={'fileToUpload': ('boss.png', f, 'image/png')},
            timeout=30)
        print('catbox:', resp.status_code, resp.text[:500])
except Exception as e:
    print(f'catbox failed: {e}')

# Try 0x0.st
try:
    with open(img_path, 'rb') as f:
        resp = requests.post('https://0x0.st', files={'file': ('boss.png', f, 'image/png')}, timeout=30)
        print('0x0:', resp.status_code, resp.text[:500])
except Exception as e:
    print(f'0x0 failed: {e}')
