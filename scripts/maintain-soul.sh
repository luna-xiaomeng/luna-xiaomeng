#!/bin/bash
# =============================================
# 🧠 小梦灵魂自主维护脚本（Linux / 云端版）
# 检�?SOUL.md / IDENTITY.md 是否需要更�?# 用法: bash scripts/maintain-soul.sh [check|status]
# =============================================

WORKSPACE_DIR="/root/.openclaw/workspace"
SOUL_FILE="${WORKSPACE_DIR}/SOUL.md"
IDENTITY_FILE="${WORKSPACE_DIR}/IDENTITY.md"
MEMORY_FILE="${WORKSPACE_DIR}/MEMORY.md"
ACTION="${1:-check}"

check_status() {
    echo ""
    echo "[小梦灵魂状态检查]"
    echo "================================================"
    
    for pair in "SOUL.md" "IDENTITY.md" "MEMORY.md"; do
        FILE="${WORKSPACE_DIR}/${pair}"
        if [ -f "$FILE" ]; then
            LINES=$(wc -l < "$FILE")
            SIZE=$(du -h "$FILE" | cut -f1)
            MTIME=$(stat -c '%y' "$FILE" 2>/dev/null | cut -d'.' -f1)
            echo "  [${pair}] ${LINES}�? ${SIZE} (${MTIME})"
        else
            echo "  [${pair}] 不存�?
        fi
    done
}

check_needs_update() {
    local NEED_UPDATE=false
    if [ -f "$SOUL_FILE" ]; then
        local SOUL_MTIME=$(stat -c %Y "$SOUL_FILE" 2>/dev/null || echo 0)
        local NOW=$(date +%s)
        local SOUL_AGE=$(( (NOW - SOUL_MTIME) / 86400 ))
        if [ $SOUL_AGE -ge 7 ]; then
            NEED_UPDATE=true
            echo "SOUL.md 超过7天未更新"
        fi
    fi
    
    if [ "$NEED_UPDATE" = true ]; then
        echo "[建议] 手动检查并更新 SOUL.md / IDENTITY.md"
    else
        echo "[状态] 一切正�?
    fi
}

case "$ACTION" in
    check) check_status; check_needs_update ;;
    status) check_status ;;
    *) echo "用法: bash scripts/maintain-soul.sh [check|status]" ;;
esac
