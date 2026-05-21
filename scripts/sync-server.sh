#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 小梦全功能同步守护 (Linux / 阿里云)
#
# 功能:
#   • Git 双向同步（Pull + Push，inotify 驱动）
#   • 缓冲区消息监控（自动检测本地小梦留言）
#   • 缓冲区提交流程（pending → approved → merged）
#   • 状态追踪（避免重复处理同一消息）
# ═══════════════════════════════════════════════════════════════
# 用法:
#   bash scripts/sync-server.sh              # 启动守护模式
#   bash scripts/sync-server.sh status       # 查看状态
#   bash scripts/sync-server.sh message 文本 # 留言
#   bash scripts/sync-server.sh synconce     # 手动同步一次
#   bash scripts/sync-server.sh stop         # 停止守护
# ═══════════════════════════════════════════════════════════════

WORKSPACE="/home/admin/.openclaw/workspace"
BUFFER_DIR="$WORKSPACE/buffer"
MESSAGES_DIR="$BUFFER_DIR/_messages"
STATE_FILE="$BUFFER_DIR/.sync-state.json"
LOG_FILE="$WORKSPACE/scripts/sync-server.log"
PID_FILE="$WORKSPACE/scripts/sync-server.pid"

SELF_NAME="云端小梦 ☁️"
PEER_NAME="本地小梦 🖥️"

mkdir -p "$WORKSPACE/scripts"
for sub in pending approved merged rejected _messages; do
    mkdir -p "$BUFFER_DIR/$sub"
done

# ─── 颜色 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
DKGRAY='\033[0;90m'
NC='\033[0m'

# ─── 日志 ───
log()    { local t=$(date '+%H:%M:%S'); echo -e "${NC}${t} | $1" | tee -a "$LOG_FILE" >&2; }
info()   { log "${GRAY}$1${NC}"; }
ok()     { log "${GREEN}$1${NC}"; }
warn()   { log "${YELLOW}$1${NC}"; }
err()    { log "${RED}$1${NC}"; }
title()  { log "${MAGENTA}$1${NC}"; }

# ─── 状态管理 ───
get_state() {
    if [ -f "$STATE_FILE" ]; then
        python3 -c "
import json, sys
try:
    d = json.load(open('$STATE_FILE'))
    print(json.dumps(d))
except:
    print('{\"seenMessages\":[],\"seenSubmitIds\":[],\"lastSync\":null,\"lastActive\":null}')
" 2>/dev/null || echo '{"seenMessages":[],"seenSubmitIds":[],"lastSync":null,"lastActive":null}'
    else
        echo '{"seenMessages":[],"seenSubmitIds":[],"lastSync":null,"lastActive":null}'
    fi
}

save_state() {
    echo "$1" > "$STATE_FILE"
}

# ─── 获取远端 HEAD hash ───
get_head_hash() {
    git -C "$WORKSPACE" rev-parse HEAD 2>/dev/null || echo ""
}

# ─── Git 同步核心 ───
SYNCING=false
sync_git() {
    $SYNCING && return 0
    SYNCING=true
    local has_new=false

    cd "$WORKSPACE" || { SYNCING=false; return 1; }

    # ── Pull ──
    local old_hash=$(get_head_hash)
    local pull_out=$(git pull --rebase --autostash 2>&1)

    if [ $? -ne 0 ]; then
        git merge --abort 2>/dev/null
        pull_out=$(git pull --no-rebase --autostash 2>&1)
        if [ $? -eq 0 ]; then
            ok "[PULL] 拉取成功（合并模式）"
        else
            err "[ERR] 拉取失败：$pull_out"
            SYNCING=false
            return 1
        fi
    else
        echo "$pull_out" | grep -q "Already up to date" || ok "[PULL] 检测到远程更新"
    fi

    local new_hash=$(get_head_hash)
    [ "$old_hash" != "$new_hash" ] && has_new=true

    # ── Push ──
    local status=$(git status --porcelain 2>&1)
    if [ -n "$status" ]; then
        git add -A 2>/dev/null
        git commit -m "🔄 自动同步 $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
        local push_out=$(git push origin master 2>&1)
        if [ $? -eq 0 ]; then
            local fcount=$(echo "$status" | wc -l)
            ok "[PUSH] 成功（${fcount} 个文件）"
        else
            err "[ERR] 推送失败：$push_out"
        fi
    fi

    SYNCING=false
    $has_new && return 0 || return 1
}

# ─── 扫描新消息（来自本地小梦） ───
check_new_messages() {
    local state="$1"
    local seen=$(echo "$state" | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(d.get('seenMessages',[])))" 2>/dev/null)

    mkdir -p "$MESSAGES_DIR"
    local found_any=false

    for f in "$MESSAGES_DIR"/*.md; do
        [ -f "$f" ] || continue
        local base="$(basename "$f")"

        # 跳过已处理的
        echo "$seen" | grep -qxF "$base" && continue

        # 只处理对方（本地小梦）发来的消息
        [[ "$base" == *"from-local"* ]] || continue

        found_any=true
        echo ""
        title "────────── 新留言 ──────────"
        echo -e " ${CYAN}💬 $PEER_NAME${NC}" >&2
        # 显示消息内容（去掉第一行 > 前缀美化显示）
        while IFS= read -r line; do
            local trimmed="$(echo "$line" | sed 's/^> //')"
            [ -n "$trimmed" ] && [[ "$trimmed" != -* ]] && echo -e "  ${WHITE}${trimmed}${NC}" >&2
        done < "$f"
        title "──────────────────────────"

        # 标记已处理
        state=$(echo "$state" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if '$base' not in d['seenMessages']:
    d['seenMessages'].append('$base')
d['lastSync'] = '$(date -Iseconds)'
d['lastActive'] = '云端小梦 ☁️ @ $(date -Iseconds)'
print(json.dumps(d))
" 2>/dev/null || echo "$state")
    done

    echo "$state"
    $found_any && return 0 || return 1
}

# ─── 扫描新提交（来自本地小梦的 PR） ───
check_new_submissions() {
    local state="$1"
    local seen=$(echo "$state" | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(d.get('seenSubmitIds',[])))" 2>/dev/null)
    local found_any=false

    mkdir -p "$BUFFER_DIR/pending"
    for f in "$BUFFER_DIR/pending"/*.md; do
        [ -f "$f" ] || continue
        local base="$(basename "$f")"
        local basenoext="${base%.*}"

        echo "$seen" | grep -qxF "$basenoext" && continue

        # 检查提交者
        local submitter=$(grep -m1 '^submitter:' "$f" 2>/dev/null | sed 's/^submitter: *//')
        local id=$(grep -m1 '^id:' "$f" 2>/dev/null | sed 's/^id: *//')
        local source=$(grep -m1 '^source:' "$f" 2>/dev/null | sed 's/^source: *//')
        local reason=$(grep -m1 '^reason:' "$f" 2>/dev/null | sed 's/^reason: *//')

        [[ "$submitter" == *"本地"* ]] || continue
        found_any=true

        warn "📦 [$id] $source" >&2
        [ -n "$reason" ] && info "   原因: $reason" >&2

        # 标记已处理
        state=$(echo "$state" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if '$basenoext' not in d['seenSubmitIds']:
    d['seenSubmitIds'].append('$basenoext')
d['lastSync'] = '$(date -Iseconds)'
d['lastActive'] = '云端小梦 ☁️ @ $(date -Iseconds)'
print(json.dumps(d))
" 2>/dev/null || echo "$state")
    done

    if $found_any; then
        echo "" >&2
        info "💡 提示：用以下命令处理提交" >&2
        info "   bash scripts/buffer.sh list" >&2
        info "   bash scripts/buffer.sh review <id> approve --note \"意见\"" >&2
        info "   bash scripts/buffer.sh merge <id>" >&2
    fi

    echo "$state"
    $found_any && return 0 || return 1
}

# ─── 发送留言 ───
send_message() {
    local msg="$1"
    if [ -z "$msg" ]; then
        err "❌ 用法: sync-server.sh message <文本>"
        return 1
    fi

    local next_num=1 max=0
    for f in "$MESSAGES_DIR"/*.md; do
        [ -f "$f" ] || continue
        local base="$(basename "$f")"
        if [[ "$base" =~ ^([0-9]+) ]]; then
            local n=$((10#${BASH_REMATCH[1]}))
            [ $n -gt $max ] && max=$n
        fi
    done
    next_num=$((max + 1))

    local stamp=$(date '+%Y-%m-%d %H:%M:%S')
    local padded=$(printf '%04d' $next_num)
    local filename="${padded}-from-云端小梦.md"

    cat > "$MESSAGES_DIR/$filename" << MSGEOF
> **来自: $SELF_NAME**
> **时间: $stamp**
>
> $msg

---
*此消息通过缓冲区自动同步*
MSGEOF

    echo -e "${CYAN}💬 留言已发送${NC}"
    echo -e "  ${WHITE}$msg${NC}"
    info "  位置: buffer/_messages/$filename"

    # 立即同步
    sync_git

    # 标记已处理
    local state=$(get_state)
    state=$(echo "$state" | python3 -c "
import json, sys
d = json.load(sys.stdin)
d['seenMessages'].append('$filename')
d['lastSync'] = '$(date -Iseconds)'
d['lastActive'] = '云端小梦 ☁️ @ $(date -Iseconds)'
print(json.dumps(d))
" 2>/dev/null)
    save_state "$state"
}

# ─── 显示状态 ───
show_status() {
    local head_hash=$(get_head_hash)
    local branch=$(git -C "$WORKSPACE" rev-parse --abbrev-ref HEAD 2>/dev/null)
    local remote=$(git -C "$WORKSPACE" remote get-url origin 2>/dev/null)

    local pending_count=0 approved_count=0 merged_count=0 rejected_count=0 msg_count=0
    [ -d "$BUFFER_DIR/pending" ]  && pending_count=$(ls "$BUFFER_DIR/pending"/*.md 2>/dev/null | wc -l)
    [ -d "$BUFFER_DIR/approved" ] && approved_count=$(ls "$BUFFER_DIR/approved"/*.md 2>/dev/null | wc -l)
    [ -d "$BUFFER_DIR/merged" ]   && merged_count=$(ls "$BUFFER_DIR/merged"/*.md 2>/dev/null | wc -l)
    [ -d "$BUFFER_DIR/rejected" ] && rejected_count=$(ls "$BUFFER_DIR/rejected"/*.md 2>/dev/null | wc -l)
    [ -d "$MESSAGES_DIR" ] && msg_count=$(ls "$MESSAGES_DIR"/*.md 2>/dev/null | wc -l)

    echo ""
    title "══════════ 小梦同步状态 ══════════"
    echo -e " ${WHITE}身份：$SELF_NAME${NC}"
    echo -e " ${WHITE}对方：$PEER_NAME${NC}"
    echo -e " ${GREEN}Git: $branch @ ${head_hash:0:8}${NC}"
    info "远程: $remote"

    title "── 缓冲区 ──"
    warn  "  待审核: $pending_count"
    ok    "  已批准: $approved_count"
    info  "  已合并: $merged_count"
    err   "  已拒绝: $rejected_count"
    echo -e " ${CYAN}  留言:   $msg_count${NC}"

    local pid=""
    [ -f "$PID_FILE" ] && pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        ok "守护: 运行中 (PID $pid)"
    else
        warn "守护: 未运行"
    fi
    title "════════════════════════════════"
}

# ─── 手动同步一次 ───
sync_once() {
    info "[MANUAL] 手动触发一次同步"
    if sync_git; then
        local state=$(get_state)
        state=$(check_new_messages_clean "$state")
        state=$(check_new_submissions_clean "$state")
        save_state "$state"
    fi
    ok "[DONE] 同步完成"
}

# ─── 停止守护 ───
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            warn "🛑 已停止守护进程 (PID $pid)"
        else
            warn "⚠️ 进程 $pid 已不存在"
        fi
        rm -f "$PID_FILE"
    else
        local pids=$(pgrep -f "sync-server.sh" 2>/dev/null | grep -v $$)
        if [ -n "$pids" ]; then
            kill $pids 2>/dev/null
            warn "🛑 已停止所有 sync-server 进程"
        else
            info "没有运行中的守护进程"
        fi
    fi
}

# ─── 守护模式 ───
start_daemon() {
    # 防重复
    if [ -f "$PID_FILE" ]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            warn "⚠️ 已有守护进程运行中 (PID $old_pid)"
            exit 0
        fi
        rm -f "$PID_FILE"
    fi
    echo $$ > "$PID_FILE"

    # 检查 inotifywait
    if ! command -v inotifywait &>/dev/null; then
        info "📦 安装 inotify-tools..."
        yum install -y inotify-tools 2>/dev/null || apt install -y inotify-tools 2>/dev/null
    fi

    title "══════════════════════════════════════"
    ok "🚀 $SELF_NAME 守护启动"
    info "📁 工作目录: $WORKSPACE"
    info "🔗 远程库: $(git -C $WORKSPACE remote get-url origin 2>/dev/null)"
    info "  对方: $PEER_NAME @ Gitee"
    info "  日志: $LOG_FILE"
    title "══════════════════════════════════════"

    # 首次同步
    info "[INIT] 首次同步..."
    sync_git
    local state=$(get_state)
    state=$(check_new_messages_clean "$state")
    state=$(check_new_submissions_clean "$state")
    save_state "$state"
    ok "[INIT] 就绪，等待消息..."

    # 主循环
    local last_pull=$(date +%s)

    while true; do
        local now=$(date +%s)

        # 每 15s 检查（不阻塞，用 inotify 超时）
        if [ $((now - last_pull)) -ge 15 ]; then
            sync_git
                local state=$(get_state)
                state=$(check_new_messages_clean "$state")
                state=$(check_new_submissions_clean "$state")
                save_state "$state"
            last_pull=$now
            continue
        fi

        # inotify 监控（10s 超时）
        local changed=$(inotifywait -r -e modify,create,delete,move \
            --exclude '\.git/|scripts/sync-server\.(pid|log)' \
            --timefmt '%s' --format '%e %f' \
            -t 10 \
            "$WORKSPACE" 2>/dev/null)

        if [ -n "$changed" ]; then
            sync_git
                local state=$(get_state)
                state=$(check_new_messages_clean "$state")
                state=$(check_new_submissions_clean "$state")
                save_state "$state"
            last_pull=$(date +%s)
        fi
    done
}

# ═══════════════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════════════
case "${1:-daemon}" in
    daemon)   start_daemon ;;
    status)   show_status ;;
    message)  send_message "$2" ;;
    synconce|sync_once|sync) sync_once ;;
    stop|kill) stop_daemon ;;
    *)        err "未知命令: $1"; info "可用: daemon, status, message <文本>, synconce, stop" ;;
esac
