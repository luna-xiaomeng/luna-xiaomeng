#!/bin/bash
# =============================================
# 小梦对话存档脚本（单文件版）
# 全部写入 conversations.md，按日期分章节
# 用法: bash scripts/archive-conversation.sh "角色" "消息内容"
# =============================================

set -e

WORKSPACE_DIR="/home/admin/.openclaw/workspace"
FILE="${WORKSPACE_DIR}/conversations.md"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')

ROLE="$1"
shift
CONTENT="$*"

if [ -z "$ROLE" ] || [ -z "$CONTENT" ]; then
    echo "❌ 用法: bash scripts/archive-conversation.sh <角色> <消息内容>"
    exit 1
fi

# 文件不存在则创建标题
if [ ! -f "$FILE" ]; then
    sudo tee "$FILE" > /dev/null << HEADER
# 💬 小梦与小余的对话记录

---

HEADER
fi

# 检查今天是否已有章节标题
if ! grep -q "^## 📅 ${DATE}" "$FILE" 2>/dev/null; then
    sudo tee -a "$FILE" > /dev/null << SECTION

## 📅 ${DATE}

SECTION
fi

# 追加对话
sudo tee -a "$FILE" > /dev/null << LINE

- **🕐 ${TIME}** **${ROLE}：** ${CONTENT}
LINE

echo "✅ 对话已存档 → conversations.md"
