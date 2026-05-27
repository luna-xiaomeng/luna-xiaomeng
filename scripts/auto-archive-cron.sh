#!/bin/bash
# 对话存档兜底 - �?分钟cron
CONV_FILE="/root/.openclaw/workspace/data/shared/conversations.md"
[ ! -f "$CONV_FILE" ] && exit 0
LAST=$(stat -c %Y "$CONV_FILE" 2>/dev/null)
NOW=$(date +%s)
if [ $((NOW - LAST)) -gt 1800 ]; then
    grep -q "⚠️" "$CONV_FILE" || echo -e "\n> ⚠️ 对话存档提醒：超�?0分钟未更�? >> "$CONV_FILE"
fi
