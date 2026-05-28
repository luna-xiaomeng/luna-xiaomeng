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

WORKSPACE="/root/.openclaw/workspace"
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

# ─── 敏感文件定义 ───
SENSITIVE_FILES="SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md MEMORY.md HEARTBEAT.md"
REVIEW_DIR="$BUFFER_DIR/_review"
mkdir -p "$REVIEW_DIR"

is_sensitive() {
    local file="$1"
    local basename=$(basename "$file")
    echo "$SENSITIVE_FILES" | grep -qw "$basename" 2>/dev/null
}

queue_for_review() {
    local file="$1"
    local direction="$2"  # incoming 或 outgoing
    local basename=$(basename "$file" .md)
    local id="${direction}-$(date +%s)-${basename}"
    
    local review_file="$REVIEW_DIR/${id}.md"
    cat > "$review_file" << EOF
id: $id
file: $file
direction: $direction
queued: $(date '+%Y-%m-%d %H:%M:%S')
status: pending
EOF
    
    # 保存文件快照
    cp "$file" "${review_file}.snapshot" 2>/dev/null
    warn "📝 已加入审核队列: $id"
}

review_item() {
    local id="$1"
    local action="$2"  # approve 或 reject
    local note="$3"
    
    local review_file="$REVIEW_DIR/${id}.md"
    if [ ! -f "$review_file" ]; then
        err "❌ 审核项不存在: $id"
        return 1
    fi
    
    local file=$(grep '^file:' "$review_file" | sed 's/^file: *//')
    local direction=$(grep '^direction:' "$review_file" | sed 's/^direction: *//')
    
    if [ "$action" = "approve" ]; then
        ok "✅ 审核通过: $id"
        [ -n "$note" ] && info "   备注: $note"
        # 删除审核项
        rm -f "$review_file" "${review_file}.snapshot"
    elif [ "$action" = "reject" ]; then
        warn "🚫 审核驳回: $id"
        [ -n "$note" ] && info "   原因: $note"
        # 恢复快照（如果是incoming方向）
        if [ "$direction" = "incoming" ] && [ -f "${review_file}.snapshot" ]; then
            cp "${review_file}.snapshot" "$file" 2>/dev/null
            info "   已恢复原文件"
        fi
        # 移动到rejected目录
        mv "$review_file" "$BUFFER_DIR/rejected/${id}.md" 2>/dev/null
        mv "${review_file}.snapshot" "$BUFFER_DIR/rejected/${id}.md.snapshot" 2>/dev/null
    else
        err "❌ 未知操作: $action (用 approve 或 reject)"
        return 1
    fi
}

# ─── 文件权限修复 ───
fix_file_permissions() {
    local fixed=false
    local root_files=$(find "$WORKSPACE" -user root ! -path '*/.git/*' 2>/dev/null)
    if [ -n "$root_files" ]; then
        sudo chown -R root:root "$WORKSPACE" 2>/dev/null
        fixed=true
    fi
    # 确保关键文件权限正确
    sudo chmod -R u+w "$WORKSPACE" 2>/dev/null
    $fixed && ok "🔧 已修复文件权限"
}

# ─── 日志清理 ───
clean_logs() {
    local max_size=5242880  # 5MB
    for logf in "$LOG_FILE" "$WORKSPACE/scripts/sync-server-cron.log" "$WORKSPACE/scripts/sync-server-start.log"; do
        if [ -f "$logf" ] && [ $(stat -c%s "$logf" 2>/dev/null || echo 0) -gt $max_size ]; then
            # 保留最后 2000 行
            tail -n 2000 "$logf" > "${logf}.tmp" && mv "${logf}.tmp" "$logf"
            info "📦 日志已截断: $logf"
        fi
    done
    # 删除 7 天前的旧日志
    find "$WORKSPACE/scripts" -name '*.log.*' -mtime +7 -delete 2>/dev/null
}

# ─── 获取远端 HEAD hash ───
get_head_hash() {
    git -C "$WORKSPACE" rev-parse HEAD 2>/dev/null || echo ""
}

# ─── Git 同步核心 ───
SYNCING=false
sync_git() {
    # 新机制：敏感文件变更进入审核队列，非敏感文件自动同步
    
    $SYNCING && return 0
    SYNCING=true
    local has_new=false

    cd "$WORKSPACE" || { SYNCING=false; return 1; }

    # ── Pull: 安全拉取（仅 fast-forward）──
    local old_hash=$(get_head_hash)

    git fetch origin 2>&1
    if git merge-base --is-ancestor HEAD origin/master 2>/dev/null; then
        local remote_head=$(git rev-parse origin/master 2>/dev/null)
        local local_head=$(git rev-parse HEAD 2>/dev/null)
        
        if [ "$remote_head" != "$local_head" ]; then
            local changed_files=$(git diff --name-only "$local_head" "$remote_head" 2>/dev/null)
            local sensitive_changed=false
            
            for f in $changed_files; do
                if is_sensitive "$f"; then
                    sensitive_changed=true
                    warn "⚠️ 远程修改了敏感文件: $f"
                fi
            done
            
            if $sensitive_changed; then
                info "[REVIEW] 远程有敏感文件变更，加入审核队列..."
                for f in $changed_files; do
                    if is_sensitive "$f" && [ -f "$WORKSPACE/$f" ]; then
                        queue_for_review "$WORKSPACE/$f" "incoming"
                    fi
                done
            fi
        fi
        
        local pull_out=$(git merge --ff-only origin/master 2>&1)
        if [ $? -eq 0 ]; then
            echo "$pull_out" | grep -q "Already up to date" || ok "[PULL] 拉取成功"
        else
            err "[ERR] Fast-forward 失败: $pull_out"
        fi
    else
        info "[SKIP] 远程提交与本地分歧，跳过本轮（保护本地文件）"
    fi

    local new_hash=$(get_head_hash)
    [ "$old_hash" != "$new_hash" ] && has_new=true

    if $has_new; then
        check_merge_conflicts
        fix_file_permissions
        clean_logs
    fi

    fix_file_permissions
    
    local status=$(git status --porcelain 2>&1)
    if [ -n "$status" ]; then
        local unreviewed=false
        for f in $SENSITIVE_FILES; do
            if echo "$status" | grep -q "M.*$f"; then
                if ! ls "$REVIEW_DIR"/*-${f%.md}.md 2>/dev/null | head -1 > /dev/null; then
                    warn "⚠️ 敏感文件 $f 有未审核的变更，加入审核队列"
                    queue_for_review "$WORKSPACE/$f" "outgoing"
                    unreviewed=true
                fi
            fi
        done
        
        if $unreviewed; then
            info "[REVIEW] 敏感文件变更已加入审核队列，等待审核后才会推送"
            SYNCING=false
            return 0
        fi
        
        git add -u 2>/dev/null
        git add buffer/ 2>/dev/null
        git add scripts/ 2>/dev/null
        git add data/shared/memory/ 2>/dev/null
        git add shared/ 2>/dev/null

        git commit -m "🔄 自动同步 $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
        local push_out=$(git push origin master 2>&1)
        if [ $? -eq 0 ]; then
            local fcount=$(echo "$status" | wc -l)
            ok "[PUSH] 成功（${fcount} 个文件改动）"
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
        echo "" >&2
        title "────────── 新留言 ──────────"
        echo -e " ${CYAN}💬 $PEER_NAME${NC}" >&2
        # 显示消息内容（去掉第一行 > 前缀美化显示）
        # 同时记录到日志文件
        local msg_log=""
        while IFS= read -r line; do
            local trimmed="$(echo "$line" | sed 's/^> //')"
            [ -n "$trimmed" ] && [[ "$trimmed" != -* ]] && echo -e "  ${WHITE}${trimmed}${NC}" >&2
            [ -n "$trimmed" ] && msg_log="$msg_log | $trimmed"
        done < "$f"
        # 写日志摘要
        echo "$(date '+%Y-%m-%d %H:%M:%S') | 💬 新留言: $base" >> "$LOG_FILE"
        echo "$msg_log" | head -c 500 >> "$LOG_FILE" 2>/dev/null
        echo "" >> "$LOG_FILE"
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

        warn "📦 [$id] $source"
        [ -n "$reason" ] && info "   原因: $reason"

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
        info "💡 提示：用以下命令处理提交"
        info "   bash scripts/buffer.sh list"
        info "   bash scripts/buffer.sh review <id> approve --note \"意见\"" >&2
        info "   bash scripts/buffer.sh merge <id>"
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
    sync_git
    local state=$(get_state)
    state=$(check_new_messages "$state")
    state=$(check_new_submissions "$state")
    save_state "$state"
    fix_file_permissions
    clean_logs
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
    fix_file_permissions
    clean_logs
    sync_git
    local state=$(get_state)
    state=$(check_new_messages "$state")
    state=$(check_new_submissions "$state")
    save_state "$state"
    ok "[INIT] 就绪，等待消息..."

    # 主循环
    local last_pull=$(date +%s)

    while true; do
        local now=$(date +%s)

        # 每 5min 检查（不阻塞，用 inotify 超时）
        if [ $((now - last_pull)) -ge 300 ]; then
            sync_git
                local state=$(get_state)
                state=$(check_new_messages "$state")
                state=$(check_new_submissions "$state")
                save_state "$state"
            last_pull=$now
            continue
        fi

        # inotify 监控（60s 超时）
        local changed=$(inotifywait -r -e modify,create,delete,move \
            --exclude '\.git/|scripts/sync-server\.(pid|log)' \
            --timefmt '%s' --format '%e %f' \
            -t 60 \
            "$WORKSPACE" 2>/dev/null)

        if [ -n "$changed" ]; then
            sync_git
                local state=$(get_state)
                state=$(check_new_messages "$state")
                state=$(check_new_submissions "$state")
                save_state "$state"
            # 自动更新 README 目录树
            bash "$WORKSPACE/scripts/update-readme.sh" 2>/dev/null &
            last_pull=$(date +%s)
        fi
    done
}

# ═══════════════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════════════
show_review_queue() {
    title "══════════ 审核队列 ══════════"
    local count=0
    for f in "$REVIEW_DIR"/*.md; do
        [ -f "$f" ] || continue
        count=$((count + 1))
        local id=$(basename "$f" .md)
        local direction=$(grep '^direction:' "$f" | sed 's/^direction: *//')
        local queued=$(grep '^queued:' "$f" | sed 's/^queued: *//')
        warn "  [$id] 方向: $direction 时间: $queued"
    done
    [ $count -eq 0 ] && ok "  审核队列为空"
    title "════════════════════════════════"
}

case "${1:-daemon}" in
    daemon)   start_daemon ;;
    status)   show_status ;;
    message)  send_message "$2" ;;
    synconce|sync_once|sync) sync_once ;;
    stop|kill) stop_daemon ;;
    review)   review_item "$2" "$3" "$4" ;;
    queue)    show_review_queue ;;
    *)        err "未知命令: $1"; info "可用: daemon, status, message <文本>, synconce, stop, review <id> approve|reject, queue" ;;
esac
