#!/bin/bash
# ════════════════════════════════════════════════════════════
# 小梦记忆双向同步守护脚本 (Linux / 阿里云服务器)
# 功能：
#   1. inotify 监控文件变更 → 自动 git push 到 Gitee
#   2. 每 20 秒 git pull ← 本地/别处的变更同步到服务器
# ════════════════════════════════════════════════════════════

WORKSPACE="/home/admin/.openclaw/workspace"
LOG_FILE="$WORKSPACE/scripts/sync-server.log"
PID_FILE="$WORKSPACE/scripts/sync-server.pid"

mkdir -p "$WORKSPACE/scripts"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

# ─── 防重复启动 ───
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        log "⚠️ 已在运行 (PID: $OLD_PID)，退出"
        exit 0
    fi
fi
echo $$ > "$PID_FILE"

# ─── 检查 inotifywait ───
if ! command -v inotifywait &>/dev/null; then
    log "📦 安装 inotify-tools..."
    yum install -y inotify-tools 2>/dev/null || apt install -y inotify-tools 2>/dev/null
fi

# ─── Git 同步函数 ───
SYNCING=false
sync_git() {
    $SYNCING && return
    SYNCING=true

    cd "$WORKSPACE" || return

    # Step 1: Pull
    PULL_OUT=$(git pull --rebase --autostash 2>&1)
    if [ $? -ne 0 ]; then
        git merge --abort 2>/dev/null
        PULL_OUT=$(git pull --no-rebase --autostash 2>&1)
        log "⚠️ Pull: $PULL_OUT"
    else
        echo "$PULL_OUT" | grep -q "Already up to date" || log "⬇️ Pull 到更新"
    fi

    # Step 2: Push
    STATUS=$(git status --porcelain 2>&1)
    if [ -n "$STATUS" ]; then
        git add -A 2>/dev/null
        git commit -m "🔄 自动同步 $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
        PUSH_OUT=$(git push origin master 2>&1)
        if [ $? -eq 0 ]; then
            FILE_COUNT=$(echo "$STATUS" | wc -l)
            log "⬆️ Push 成功 (${FILE_COUNT} 文件变更)"
        else
            log "❌ Push 失败: $PUSH_OUT"
        fi
    fi

    SYNCING=false
}

# ─── 清理退出 ───
cleanup() {
    log "🛑 守护进程停止"
    rm -f "$PID_FILE"
    exit 0
}
trap cleanup SIGINT SIGTERM

# ─── 启动 ───
log "🚀 小梦双向同步守护启动 (服务器)"
log "📁 $WORKSPACE"
log "🔗 $(git -C $WORKSPACE remote get-url origin 2>/dev/null)"
log "✅ 等待文件变更..."

# 先同步一次
sync_git

# ─── 主循环 ───
# 文件监控 + 定时 Pull
LAST_PULL=$(date +%s)

while true; do
    # 定时拉取检查：每 20 秒从 Gitee pull 一次
    NOW=$(date +%s)
    if [ $((NOW - LAST_PULL)) -ge 20 ]; then
        sync_git
        LAST_PULL=$NOW
        # 刚同步过，跳过 inotify 等待，直接下一轮
        continue
    fi

    # 监控文件变更（20 秒超时，防止永久阻塞）
    CHANGED=$(inotifywait -r -e modify,create,delete,move \
        --exclude '\.git/|scripts/sync-server\.(pid|log)' \
        --timefmt '%s' --format '%e %f' \
        -t 20 \
        "$WORKSPACE" 2>/dev/null)

    # 超时（exit code 0 但无输出）→ 继续循环
    if [ $? -eq 0 ] && [ -n "$CHANGED" ]; then
        sync_git
        LAST_PULL=$(date +%s)
    fi
done
