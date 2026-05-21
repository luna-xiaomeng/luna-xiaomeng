#!/bin/bash
cd /root/egg_video

# Video 1: 鸡蛋批发看过来 (ID: 7640410564656713011)
curl -s -o ref1.mp4 \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: https://www.douyin.com/" \
  "https://v26-web.douyinvod.com/cc42959b05ada7fd07c49e21a553bc1d/6a0aaae7/video/tos/cn/tos-cn-ve-15/owqUPamEPgHgiAdiuABxwQIPKQTCJI2TPkTbI/?a=6383&ch=26&cr=3&dr=0&lr=all&cd=0%7C0%7C0%7C3&cv=1&br=961&bt=961&cs=0&ds=6&ft=pEaFx4hZffPdlW~-a1VNvAq-antLjrKqJdeuRkaD62pjljVhWL6&mime_type=video_mp4&qs=12&rc=Ozc6ODwzNDg3Zjk5Njs4NkBpanVqNWs5cmk2OzMzNGkzM0BhXzAvMjVhXmMxLS01LjExYSMwcmheMmQ0LTFhLS1kLWFzcw%3D%3D&btag=80000e00010000&cquery=100H_100K_100o_100w_100B&dy_q=1779073188&feature_id=37f92ebd2877ae8e7eba995d406c5150&l=20260518105948D5747989F6F43F16DC8C&__vid=7640410564656713011"

echo "ref1 done: $(ls -lh ref1.mp4 | awk '{print $5}')"

# Video 2: 一件也是批发价 (ID: 7640033529446796594)
curl -s -o ref2.mp4 \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: https://www.douyin.com/" \
  "https://v26-web.douyinvod.com/ebba535ae715e1129c194469f4da5ea4/6a0aaaf6/video/tos/cn/tos-cn-ve-15/oAkBDIfEBMrjtBt0gifFAdQJFiKgBqAA65j9sH/?a=6383&ch=26&cr=3&dr=0&lr=all&cd=0%7C0%7C0%7C3&cv=1&br=772&bt=772&cs=0&ds=6&ft=pEaFx4hZffPdlW~-a1VNvAq-antLjrKVJdeuRkaD62pjljVhWL6&mime_type=video_mp4&qs=12&rc=OThlN2dkNTg4ZGQzNGRmZ0Bpam5qO3M5cnlnOzMzNGkzM0BgLTRfLzMzNTYxLzBhMGJeYSNlXy4yMmRzZTBhLS1kLTBzcw%3D%3D&btag=80000e00008000&cquery=100H_100K_100o_100w_100B&dy_q=1779073210&feature_id=37f92ebd2877ae8e7eba995d406c5150&l=202605181100104682677CC592A20CC82A&__vid=7640033529446796594"

echo "ref2 done: $(ls -lh ref2.mp4 | awk '{print $5}')"

# Video 3: 正宗土鸡蛋批发 (ID: 7639657344191827243)
curl -s -o ref3.mp4 \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: https://www.douyin.com/" \
  "https://v26-web.douyinvod.com/6fc3e984b0acbf4342899e54d17c0d73/6a0aab06/video/tos/cn/tos-cn-ve-15/owoIKpZzIeyBEaCCKGGGeBf7aTALQGwABnmUE1/?a=6383&ch=26&cr=3&dr=0&lr=all&cd=0%7C0%7C0%7C3&cv=1&br=612&bt=612&cs=0&ds=6&ft=pEaFx4hZffPdlW~-a1VNvAq-antLjrK0CdeuRkaD62pjljVhWL6&mime_type=video_mp4&qs=12&rc=Zjc6PGc3ZTplZzVnaTtlaUBpajhucHY5cmxyOzMzNGkzM0BhMzIvNWMyNi8xXjBfNTQxYSNjbWhrMmRjMy9hLS1kLS9zcw%3D%3D&btag=80000e00010000&cquery=100H_100K_100o_100w_100B&dy_q=1779073224&feature_id=37f92ebd2877ae8e7eba995d406c5150&l=20260518110024E23402F30A06000D9349&__vid=7639657344191827243"

echo "ref3 done: $(ls -lh ref3.mp4 | awk '{print $5}')"

# Video 4: 一件也是源头价 (ID: 7639292454302190886)
curl -s -o ref4.mp4 \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: https://www.douyin.com/" \
  "https://v26-web.douyinvod.com/063ac9090d06fd951f7423a59543afc3/6a0aab10/video/tos/cn/tos-cn-ve-15/owIEEQA6eO3AAGB1miwgfJV35lyAWiBgN8hBBk/?a=6383&ch=26&cr=3&dr=0&lr=all&cd=0%7C0%7C0%7C3&cv=1&br=1209&bt=1209&cs=0&ds=3&ft=pEaFx4hZffPdlW~-a1VNvAq-antLjrKpCdeuRkaD62pjljVhWL6&mime_type=video_mp4&qs=0&rc=NDQ4ZTw0Njc1ZTo5ZWk5NUBpajx5Z2w5cmU2OzMzNGkzM0A2My01NTE0NjUxYF80YTBgYSNwbHJnMmRjMi9hLS1kLWFzcw%3D%3D&btag=80000e00008000&cquery=100H_100K_100o_100w_100B&dy_q=1779073236&feature_id=f5241e7604dff1d9d6c943fd20bd51a2&l=2026051811003631DFD31E539C2A0E6979&__vid=7639292454302190886"

echo "ref4 done: $(ls -lh ref4.mp4 | awk '{print $5}')"

# Video 5: 土鸡蛋批发保证品质 (ID: 7637792700812578094)
curl -s -o ref5.mp4 \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: https://www.douyin.com/" \
  "https://v26-web.douyinvod.com/47fe2392b50b9b67485f1c6fa9480c23/6a0aab22/video/tos/cn/tos-cn-ve-15/o0JSgEAvegBlftAAgHHeqAR5Kc5PY4SIQBiPee/?a=6383&ch=26&cr=3&dr=0&lr=all&cd=0%7C0%7C0%7C3&cv=1&br=2224&bt=2224&cs=0&ds=3&ft=pEaFx4hZffPdlW~-a1VNvAq-antLjrK3CdeuRkaD62pjljVhWL6&mime_type=video_mp4&qs=0&rc=aTs7NWkzNTdkaDY6O2g8ZEBpamQ3M3g5cjNoOjMzNGkzM0AtNDAwLy0yXy0xL140Ni80YSNnc3JfMmRzNXNhLS1kLS9zcw%3D%3D&btag=c0000e00010000&cquery=100B_100H_100K_100o_100w&dy_q=1779073250&feature_id=f5241e7604dff1d9d6c943fd20bd51a2&l=2026051811005091ADB389F67A4B3FD638&__vid=7637792700812578094"

echo "ref5 done: $(ls -lh ref5.mp4 | awk '{print $5}')"

echo "ALL DONE"
ls -lh ref*.mp4
