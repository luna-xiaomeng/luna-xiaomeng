#!/bin/bash
# =============================================
# 小梦对话存档脚本（单文件版）
# 全部写入 conversations.md，按日期分章�?
# 用法: bash scripts/archive-conversation.sh "角色" "消息内容"
# 注意: 云端�?"小梦(云端)"，本地用 "小梦(本地)"
# =============================================

set -e
WORKSPACE_DIR="/root/.openclaw/workspace"
FILE="${WORKSPACE_DIR}/data/shared/conversations.md"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')
ROLE="$1"
shift
CONTENT="$*"

if [ -z "$ROLE" ] || [ -z "$CONTENT" ]; then
    echo "�?用法: bash scripts/archive-conversation.sh <角色> <消息内容>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    sudo tee "$FILE" > /dev/null << HEADER
# 💬 小梦与小余的对话记录

---

HEADER
fi

if ! grep -q "^## 📅 ${DATE}" "$FILE" 2>/dev/null; then
    printf "\n## 📅 %s\n\n" "$DATE" | sudo tee -a "$FILE" > /dev/null
fi

printf "\n- **🕐 %s** **%s�?* %s\n" "$TIME" "$ROLE" "$CONTENT" | sudo tee -a "$FILE" > /dev/null
echo "�?对话已存�?�?conversations.md �?{ROLE}�?
