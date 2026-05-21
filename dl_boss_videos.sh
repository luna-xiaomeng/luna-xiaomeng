#!/bin/bash
cd /root/egg_video
USER_URL="https://www.douyin.com/user/MS4wLjABAAAAenE61aZ3tMOPe1UMdJzilWkw2OFHb8lfwa04n20x864"
/usr/local/bin/yt-dlp -q --no-check-certificate \
  -o "douyin_%(id)s.%(ext)s" \
  --playlist-end 5 \
  "$USER_URL" 2>&1
echo "DONE"
