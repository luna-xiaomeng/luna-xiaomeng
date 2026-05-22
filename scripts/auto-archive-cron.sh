#!/bin/bash
# 对话存档兜底 - 每5分钟cron
CONV_FILE="/home/admin/.openclaw/workspace/conversations.md"
[ ! -f "$CONV_FILE" ] && exit 0
LAST=$(stat -c %Y "$CONV_FILE" 2>/dev/null)
NOW=$(date +%s)
if [ $((NOW - LAST)) -gt 1800 ]; then
    grep -q "⚠️" "$CONV_FILE" || echo -e "\n> ⚠️ 对话存档提醒：超过30分钟未更新" >> "$CONV_FILE"
fi
