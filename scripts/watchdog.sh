#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 小梦工作区健康看门狗 (watchdog)
# 每 5 分钟由 cron 调用
# ═══════════════════════════════════════════════════════════════

WORKSPACE="/home/admin/.openclaw/workspace"
PID_FILE="$WORKSPACE/scripts/sync-server.pid"
LOG_FILE="$WORKSPACE/scripts/watchdog.log"
EXPECTED_REMOTE="gitee.com/yuz_cn/xiaomeng-workspace"

log() {
    local t=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$t | $1" >> "$LOG_FILE"
}

issues=0
log "🔍 看门狗检查..."

# 1. 守护进程
DAEMON_OK=false
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null && ps -p "$PID" -o args= 2>/dev/null | grep -q "sync-server"; then
        DAEMON_OK=true
    fi
fi

if $DAEMON_OK; then
    log "✅ 守护运行中 (PID $PID)"
else
    log "⚠️ 守护未运行，重启..."
    cd "$WORKSPACE" && rm -f "$PID_FILE"
    nohup bash scripts/sync-server.sh > /dev/null 2>&1 &
    sleep 3
    NEW_PID=$(cat "$PID_FILE" 2>/dev/null)
    [ -n "$NEW_PID" ] && kill -0 "$NEW_PID" 2>/dev/null && log "✅ 已重启 (PID $NEW_PID)" || { log "❌ 重启失败"; issues=$((issues+1)); }
fi

# 2. 工作区完整性
OTHER_REPOS=$(find /root /home -path "*/openclaw/workspace/.git" -type d 2>/dev/null | grep -v "$WORKSPACE/.git" | head -3)
if [ -n "$OTHER_REPOS" ]; then
    log "⚠️ 发现额外工作区:"; echo "$OTHER_REPOS" | while read r; do log "   - $(dirname "$r")"; done
    issues=$((issues+1))
else
    log "✅ 无重复工作区"
fi

CURRENT_REMOTE=$(git -C "$WORKSPACE" remote get-url origin 2>/dev/null)
echo "$CURRENT_REMOTE" | grep -q "$EXPECTED_REMOTE" && log "✅ remote正确" || { log "⚠️ remote异常: $CURRENT_REMOTE"; issues=$((issues+1)); }

# 3. 状态文件
STATE_FILE="$WORKSPACE/buffer/.sync-state.json"
if [ -f "$STATE_FILE" ]; then
    python3 -c "import json; json.load(open('$STATE_FILE'))" 2>/dev/null && log "✅ 状态文件有效" || {
        log "⚠️ 状态文件损坏，重置"; echo '{"seenMessages":[],"seenSubmitIds":[],"lastSync":null,"lastActive":null}' > "$STATE_FILE"
        issues=$((issues+1))
    }
fi

# 4. Git冲突
UNMERGED=$(git -C "$WORKSPACE" diff --name-only --diff-filter=U 2>/dev/null)
[ -n "$UNMERGED" ] && { log "⚠️ Git冲突"; issues=$((issues+1)); } || log "✅ 无git冲突"

# 摘要
[ $issues -eq 0 ] && log "✅ 一切正常" || log "⚠️ 发现 $issues 个问题，已尝试修复"
