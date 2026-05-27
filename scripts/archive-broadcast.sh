#!/bin/bash
# =============================================
# 播报自动存档脚本
# 追加到 broadcast.md，按日期分章节
# 用法: 
#   交互式:  bash scripts/archive-broadcast.sh
#   直接传:  bash scripts/archive-broadcast.sh "播报内容..."
# =============================================

set -e

WORKSPACE_DIR="/home/admin/.openclaw/workspace"
FILE="${WORKSPACE_DIR}/data/shared/broadcast.md"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')

if [ -n "$1" ]; then
    CONTENT="$*"
else
    echo "📝 请输入今晚的播报内容（可多行，Ctrl+D 结束）："
    CONTENT=$(cat)
fi

# 文件不存在则创建标题
if [ ! -f "$FILE" ]; then
    sudo tee "$FILE" > /dev/null << HEADER
# 📡 小梦播报档案

> 每晚8点，小梦为你播报天气、时事和电商热点 💕

---

HEADER
fi

# 追加播报内容
sudo tee -a "$FILE" > /dev/null << BROADCAST

## 📅 ${DATE} — 晚间播报

${CONTENT}

---

BROADCAST

echo "✅ 播报已存档 → broadcast.md（${DATE}）"
