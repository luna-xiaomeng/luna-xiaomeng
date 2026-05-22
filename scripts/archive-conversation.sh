#!/bin/bash
# =============================================
# 小梦对话自动存档脚本
# 用法: bash scripts/archive-conversation.sh "角色" "消息内容"
# 示例: bash scripts/archive-conversation.sh "小余" "今天天气怎么样"
#       bash scripts/archive-conversation.sh "小梦" "今天20度哦"
# =============================================

set -e

WORKSPACE_DIR="/home/admin/.openclaw/workspace"
CONV_DIR="${WORKSPACE_DIR}/conversations"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')
FILE="${CONV_DIR}/${DATE}.md"

ROLE="$1"
shift
CONTENT="$*"

# 参数检查
if [ -z "$ROLE" ] || [ -z "$CONTENT" ]; then
    echo "❌ 用法: bash scripts/archive-conversation.sh <角色> <消息内容>"
    exit 1
fi

# 创建目录和文件头
if [ ! -f "$FILE" ]; then
    cat > "$FILE" << HEADER
# 💬 小梦与小余的对话记录 - ${DATE}

---

HEADER
fi

# 追加对话
{
    echo ""
    echo "## 🕐 ${TIME}"
    echo ""
    echo "**${ROLE}：** ${CONTENT}"
    echo ""
} >> "$FILE"

echo "✅ 对话已存档 → conversations/${DATE}.md"
