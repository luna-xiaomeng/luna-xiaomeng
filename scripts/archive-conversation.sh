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
WEEKDAY=$(date '+%A')

ROLE="$1"
shift
CONTENT="$*"

if [ -z "$ROLE" ] || [ -z "$CONTENT" ]; then
    echo "❌ 用法: bash scripts/archive-conversation.sh <角色> <消息内容>"
    exit 1
fi

# 如果文件不存在或今天还没有日期标题，先创建
if [ ! -f "$FILE" ]; then
    cat > "$FILE" << HEADER
# 💬 小梦与小余的对话记录

---

HEADER
fi

# 检查今天是否已有章节标题
if ! grep -q "^## 📅 ${DATE}" "$FILE" 2>/dev/null; then
    echo "" >> "$FILE"
    echo "## 📅 ${DATE}" >> "$FILE"
    echo "" >> "$FILE"
fi

# 追加对话
{
    echo "- **🕐 ${TIME}** **${ROLE}：** ${CONTENT}"
} >> "$FILE"

echo "✅ 对话已存档 → conversations.md"
