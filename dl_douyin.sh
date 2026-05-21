#!/bin/bash
cd /root/egg_video
curl -L -s -o douyin_source.mp4 \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -H "Referer: https://www.douyin.com/" \
  -H "Cookie: __ac_nonce=06a0a6c5100849b85a971; __ac_signature=_02B4Z6wo00f017kBTZAAAIDANKn0Ghr7TFu5IUkAAIRS1b" \
  "https://v26-web.douyinvod.com/0771d11eaf665f40560a116465854f67/6a0a9694/video/tos/cn/tos-cn-ve-15/oIj2QyLVYe0Zfzp1CgGAIp3s2YnAcEXDDeIYeH/?a=6383&ch=26&cr=3&dr=0&lr=all&cd=0%7C0%7C0%7C3&cv=1&br=849&bt=849&cs=0&ds=6&ft=pEaFx4hZffPdlW~-a1VNvAq-antLjrKpXseuRkaD62pjljVhWL6&mime_type=video_mp4&qs=12&rc=NDc3ZTkzM2g5ZWQ2NjpmZUBpanNrNnU5cmV5OjMzNGkzM0AwYDRjMjE2XjAxNi5jMjBeYSNwam0wMmQ0Xm9hLS1kLWFzcw%3D%3D&btag=c0000e00010000&cquery=100H_100K_100o_100w_100B&dy_q=1779067988&feature_id=37f92ebd2877ae8e7eba995d406c5150&l=20260518093308D571524E2158DD4AEC9F&__vid=7635842437453188398"
echo "EXIT: $?"
ls -lh douyin_source.mp4
file douyin_source.mp4
