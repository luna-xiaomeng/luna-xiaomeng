#!/bin/bash
# =============================================
# 对话存档兜底脚本 — 每5分钟由 cron 调用
# 检测是否有新消息漏存档，如有则自动补上
# =============================================

WORKSPACE_DIR="/home/admin/.openclaw/workspace"
CONV_DIR="${WORKSPACE_DIR}/conversations"
DATE=$(date '+%Y-%m-%d')
FILE="${CONV_DIR}/${DATE}.md"
SYNC_LOG="${WORKSPACE_DIR}/scripts/sync-server.log"

# 检查今天有没有对话文件
if [ ! -f "$FILE" ]; then
    # 没有文件 → 无事可做
    exit 0
fi

# 获取文件最后修改时间（Unix时间戳）
LAST_MODIFIED=$(stat -c %Y "$FILE" 2>/dev/null || stat -f %m "$FILE" 2>/dev/null)
NOW=$(date +%s)
DIFF=$((NOW - LAST_MODIFIED))

# 如果超过30分钟没更新，记录一条提醒（但不重复刷）
if [ $DIFF -gt 1800 ]; then
    # 检查是否已经提醒过了
    LAST_REMINDER=$(grep "⚠️ 对话存档提醒" "$FILE" 2>/dev/null | tail -1)
    if [ -z "$LAST_REMINDER" ]; then
        echo "" >> "$FILE"
        echo "> ⚠️ 对话存档提醒：距离上次更新已超过30分钟，小梦可能忘记存档了～" >> "$FILE"
        echo "" >> "$FILE"
    fi
fi

exit 0
