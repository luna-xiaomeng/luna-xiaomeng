#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🌸 小梦统一管理工具 (Linux / 阿里云)
#
# 合并了: sync-server, maintain-soul, archive-*, update-openclaw
# 保留独立: buffer.sh (复杂缓冲区管理)
#
# 用法:
#   bash scripts/xiaomeng.sh                    # 显示帮助
#   bash scripts/xiaomeng.sh status             # 状态总览（含灵魂状态）
#   bash scripts/xiaomeng.sh sync               # 手动同步一次
#   bash scripts/xiaomeng.sh daemon             # 启动守护模式
#   bash scripts/xiaomeng.sh stop               # 停止守护
#   bash scripts/xiaomeng.sh queue              # 查看审核队列
#   bash scripts/xiaomeng.sh review <id> approve|reject [备注]
#   bash scripts/xiaomeng.sh message <文本>     # 留言给本地小梦
#   bash scripts/xiaomeng.sh broadcast [内容]   # 播报存档
#   bash scripts/xiaomeng.sh archive <角色> <内容> # 对话存档
#   bash scripts/xiaomeng.sh soul [check|status] # 灵魂状态检查
#   bash scripts/xiaomeng.sh update [check|update] # OpenClaw更新
#   bash scripts/xiaomeng.sh clean              # 清理日志和旧文件
# ═══════════════════════════════════════════════════════════════

WORKSPACE="/root/.openclaw/workspace"
BUFFER_DIR="$WORKSPACE/buffer"
MESSAGES_DIR="$BUFFER_DIR/_messages"
STATE_FILE="$BUFFER_DIR/.sync-state.json"
LOG_FILE="$WORKSPACE/scripts/xiaomeng.log"
PID_FILE="$WORKSPACE/scripts/xiaomeng.pid"
REVIEW_DIR="$BUFFER_DIR/_review"

SELF_NAME="云端小梦 ☁️"
PEER_NAME="本地小梦 🖥️"

mkdir -p "$WORKSPACE/scripts" "$REVIEW_DIR"
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
    print('{\"seenMessages\":[],\"seenSubmitIds\":[],\"lastSync\":null,\"lastActive\":null}')" 2>/dev/null
    else
        echo '{"seenMessages":[],"seenSubmitIds":[],"lastSync":null,"lastActive":null}'
    fi
}

save_state() { echo "$1" > "$STATE_FILE"; }

# ─── 敏感文件 ───
SENSITIVE_FILES="SOUL.md IDENTITY.md AGENTS.md USER.md TOOLS.md MEMORY.md HEARTBEAT.md"

is_sensitive() {
    local file="$1"
    echo "$SENSITIVE_FILES" | grep -qw "$(basename "$file")" 2>/dev/null
}

queue_for_review() {
    local file="$1" direction="$2"
    local id="${direction}-$(date +%s)-$(basename "$file" .md)"
    cat > "$REVIEW_DIR/${id}.md" << EOF
id: $id
file: $file
direction: $direction
queued: $(date '+%Y-%m-%d %H:%M:%S')
status: pending
EOF
    cp "$file" "$REVIEW_DIR/${id}.snapshot" 2>/dev/null
    warn "📝 已加入审核队列: $id"
}

review_item() {
    local id="$1" action="$2" note="$3"
    local review_file="$REVIEW_DIR/${id}.md"
    [ -f "$review_file" ] || { err "❌ 审核项不存在: $id"; return 1; }
    
    local file=$(grep '^file:' "$review_file" | sed 's/^file: *//')
    local direction=$(grep '^direction:' "$review_file" | sed 's/^direction: *//')
    
    if [ "$action" = "approve" ]; then
        ok "✅ 审核通过: $id"; [ -n "$note" ] && info "   备注: $note"
        rm -f "$review_file" "$REVIEW_DIR/${id}.snapshot"
    elif [ "$action" = "reject" ]; then
        warn "🚫 审核驳回: $id"; [ -n "$note" ] && info "   原因: $note"
        [ "$direction" = "incoming" ] && [ -f "$REVIEW_DIR/${id}.snapshot" ] && {
            cp "$REVIEW_DIR/${id}.snapshot" "$file" 2>/dev/null; info "   已恢复原文件"
        }
        mv "$review_file" "$BUFFER_DIR/rejected/${id}.md" 2>/dev/null
        mv "$REVIEW_DIR/${id}.snapshot" "$BUFFER_DIR/rejected/${id}.md.snapshot" 2>/dev/null
    else
        err "❌ 未知操作: $action"; return 1
    fi
}

show_review_queue() {
    title "══════════ 审核队列 ══════════"
    local count=0
    for f in "$REVIEW_DIR"/*.md; do
        [ -f "$f" ] || continue
        count=$((count + 1))
        local direction=$(grep '^direction:' "$f" | sed 's/^direction: *//')
        local queued=$(grep '^queued:' "$f" | sed 's/^queued: *//')
        warn "  [$(basename "$f" .md)] 方向: $direction 时间: $queued"
    done
    [ $count -eq 0 ] && ok "  审核队列为空"
    title "════════════════════════════════"
}

# ─── 文件权限修复 ───
fix_file_permissions() {
    local root_files=$(find "$WORKSPACE" -user root ! -path '*/.git/*' 2>/dev/null)
    [ -n "$root_files" ] && sudo chown -R root:root "$WORKSPACE" 2>/dev/null
    sudo chmod -R u+w "$WORKSPACE" 2>/dev/null
}

# ─── 日志清理 ───
clean_logs() {
    local max_size=5242880
    for logf in "$LOG_FILE" "$WORKSPACE/scripts/xiaomeng-cron.log"; do
        if [ -f "$logf" ] && [ $(stat -c%s "$logf" 2>/dev/null || echo 0) -gt $max_size ]; then
            tail -n 2000 "$logf" > "${logf}.tmp" && mv "${logf}.tmp" "$logf"
        fi
    done
    find "$WORKSPACE/scripts" -name '*.log.*' -mtime +7 -delete 2>/dev/null
    find "$BUFFER_DIR/rejected" -name '*.md' -mtime +30 -delete 2>/dev/null
}

get_head_hash() { git -C "$WORKSPACE" rev-parse HEAD 2>/dev/null || echo ""; }

# ─── Git 同步核心 ───
SYNCING=false
sync_git() {
    $SYNCING && return 0
    SYNCING=true
    local has_new=false
    cd "$WORKSPACE" || { SYNCING=false; return 1; }

    local old_hash=$(get_head_hash)
    git fetch origin 2>&1
    
    if git merge-base --is-ancestor HEAD origin/master 2>/dev/null; then
        local remote_head=$(git rev-parse origin/master 2>/dev/null)
        local local_head=$(git rev-parse HEAD 2>/dev/null)
        
        if [ "$remote_head" != "$local_head" ]; then
            local changed_files=$(git diff --name-only "$local_head" "$remote_head" 2>/dev/null)
            for f in $changed_files; do
                is_sensitive "$f" && { warn "⚠️ 远程修改了敏感文件: $f"; queue_for_review "$WORKSPACE/$f" "incoming"; }
            done
        fi
        
        local pull_out=$(git merge --ff-only origin/master 2>&1)
        if [ $? -eq 0 ]; then
            echo "$pull_out" | grep -q "Already up to date" || ok "[PULL] 拉取成功"
        else
            err "[ERR] Fast-forward 失败: $pull_out"
        fi
    else
        info "[SKIP] 远程分歧，跳过本轮"
    fi

    local new_hash=$(get_head_hash)
    [ "$old_hash" != "$new_hash" ] && has_new=true
    $has_new && fix_file_permissions

    local status=$(git status --porcelain 2>&1)
    if [ -n "$status" ]; then
        local unreviewed=false
        for f in $SENSITIVE_FILES; do
            if echo "$status" | grep -q "M.*$f"; then
                if ! ls "$REVIEW_DIR"/*-${f%.md}.md 2>/dev/null | head -1 > /dev/null 2>&1; then
                    warn "⚠️ 敏感文件 $f 未审核，加入队列"
                    queue_for_review "$WORKSPACE/$f" "outgoing"
                    unreviewed=true
                fi
            fi
        done
        
        if $unreviewed; then
            info "[REVIEW] 敏感文件变更已加入审核队列"
            SYNCING=false; return 0
        fi
        
        git add -u 2>/dev/null
        git add buffer/ scripts/ data/shared/memory/ shared/ 2>/dev/null
        git commit -m "🔄 自动同步 $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
        local push_out=$(git push origin master 2>&1)
        if [ $? -eq 0 ]; then
            ok "[PUSH] 成功（$(echo "$status" | wc -l) 个文件改动）"
        else
            err "[ERR] 推送失败：$push_out"
        fi
    fi
    SYNCING=false
    $has_new && return 0 || return 1
}

# ─── 消息扫描 ───
check_new_messages() {
    local state="$1"
    local seen=$(echo "$state" | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(d.get('seenMessages',[])))" 2>/dev/null)
    local found_any=false

    for f in "$MESSAGES_DIR"/*.md; do
        [ -f "$f" ] || continue
        local base="$(basename "$f")"
        echo "$seen" | grep -qxF "$base" && continue
        [[ "$base" == *"from-local"* ]] || continue
        found_any=true
        
        title "────────── 新留言 ──────────"
        echo -e " ${CYAN}💬 $PEER_NAME${NC}" >&2
        while IFS= read -r line; do
            local trimmed="$(echo "$line" | sed 's/^> //')"
            [ -n "$trimmed" ] && [[ "$trimmed" != -* ]] && echo -e "  ${WHITE}${trimmed}${NC}" >&2
        done < "$f"
        title "──────────────────────────"
        
        state=$(echo "$state" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if '$base' not in d['seenMessages']: d['seenMessages'].append('$base')
d['lastSync'] = '$(date -Iseconds)'; d['lastActive'] = '$SELF_NAME @ $(date -Iseconds)'
print(json.dumps(d))" 2>/dev/null || echo "$state")
    done
    echo "$state"
    $found_any && return 0 || return 1
}

# ─── 发送留言 ───
send_message() {
    [ -z "$1" ] && { err "❌ 用法: $0 message <文本>"; return 1; }
    local max=0
    for f in "$MESSAGES_DIR"/*.md; do
        [ -f "$f" ] || continue
        [[ "$(basename "$f")" =~ ^([0-9]+) ]] && { local n=$((10#${BASH_REMATCH[1]})); [ $n -gt $max ] && max=$n; }
    done
    local padded=$(printf '%04d' $((max + 1)))
    local filename="${padded}-from-云端小梦.md"
    cat > "$MESSAGES_DIR/$filename" << EOF
> **来自: $SELF_NAME**
> **时间: $(date '+%Y-%m-%d %H:%M:%S')**
>
> $1

---
*此消息通过缓冲区自动同步*
EOF
    ok "💬 留言已发送: $1"
    sync_git
}

# ─── 状态总览 ───
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
    
    # 守护状态
    local pid=""
    [ -f "$PID_FILE" ] && pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        ok "守护: 运行中 (PID $pid)"
    else
        warn "守护: 未运行"
    fi
    title "════════════════════════════════"
    
    # 灵魂状态
    show_soul_status
}

# ─── 灵魂状态检查 (from maintain-soul.sh) ───
show_soul_status() {
    echo ""
    title "══════════ 灵魂状态 ══════════"
    for f in SOUL.md IDENTITY.md MEMORY.md; do
        if [ -f "$WORKSPACE/$f" ]; then
            local lines=$(wc -l < "$WORKSPACE/$f")
            local size=$(du -h "$WORKSPACE/$f" | cut -f1)
            local mtime=$(stat -c '%y' "$WORKSPACE/$f" 2>/dev/null | cut -d'.' -f1)
            ok "  [$f] ${lines}行 ${size} (${mtime})"
        else
            err "  [$f] 不存在"
        fi
    done
    
    # 检查是否需要更新
    local soul_mtime=$(stat -c %Y "$WORKSPACE/SOUL.md" 2>/dev/null || echo 0)
    local now=$(date +%s)
    local soul_age=$(( (now - soul_mtime) / 86400 ))
    if [ $soul_age -ge 7 ]; then
        warn "  ⚠️ SOUL.md 超过 ${soul_age} 天未更新"
    fi
    title "════════════════════════════════"
}

# ─── 播报存档 (from archive-broadcast.sh) ───
archive_broadcast() {
    local content="$*"
    local file="$WORKSPACE/data/shared/broadcast.md"
    local date=$(date '+%Y-%m-%d')
    
    if [ -z "$content" ]; then
        echo "请输入今晚的播报内容（可多行，Ctrl+D 结束）："
        content=$(cat)
    fi
    
    [ ! -f "$file" ] && echo "# 📋 小梦播报档案

> 每晚8点，小梦为你播报天气、时事和电商热点 🎯

---" > "$file"
    
    echo "

## 🌙 ${date} — 晚间播报

${content}

---" >> "$file"
    
    ok "✅ 播报已存档 → broadcast.md ($date)"
}

# ─── 对话存档 (from archive-conversation.sh) ───
archive_conversation() {
    local role="$1"; shift; local content="$*"
    [ -z "$role" ] || [ -z "$content" ] && { err "❌ 用法: $0 archive <角色> <消息内容>"; return 1; }
    
    local file="$WORKSPACE/data/shared/conversations.md"
    local date=$(date '+%Y-%m-%d')
    local time=$(date '+%H:%M')
    
    [ ! -f "$file" ] && echo "# 💬 小梦与小余的对话记录

---" > "$file"
    
    grep -q "^## 🌙 ${date}" "$file" 2>/dev/null || printf "\n## 🌙 %s\n\n" "$date" >> "$file"
    printf "\n- **🌙 %s** **%s：** %s\n" "$time" "$role" "$content" >> "$file"
    ok "✅ 对话已存档 → conversations.md ($role)"
}

# ─── OpenClaw更新 (from update-openclaw.sh) ───
update_openclaw() {
    local action="${1:-check}"
    local current=$(openclaw --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+')
    [ -z "$current" ] && current="N/A"
    
    echo ""
    title "══════════ OpenClaw 更新 ══════════"
    echo -e " 当前版本: ${GREEN}$current${NC}"
    
    local data=$(curl -s https://api.github.com/repos/openclaw/openclaw/releases/latest 2>/dev/null)
    local latest=$(echo "$data" | grep -oP '(?<=tag_name": "v)\d+\.\d+\.\d+')
    
    if [ -z "$latest" ]; then
        warn "  无法获取最新版本信息"
        title "════════════════════════════════"
        return 1
    fi
    
    echo -e " 最新版本: ${GREEN}$latest${NC}"
    
    if [ "$current" = "$latest" ]; then
        ok "  ✅ 已是最新版本"
    elif [ "$action" = "update" ]; then
        warn "  🔄 正在更新..."
        openclaw update 2>&1 | tail -5
        openclaw gateway restart 2>&1 | tail -3
        ok "  ✅ 更新完成"
    else
        warn "  ⚠️ 有新版本可用"
        info "  运行: bash scripts/xiaomeng.sh update update"
    fi
    title "════════════════════════════════"
}

# ─── 守护模式 ───
start_daemon() {
    if [ -f "$PID_FILE" ]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            warn "⚠️ 已有守护进程运行中 (PID $old_pid)"
            exit 0
        fi
        rm -f "$PID_FILE"
    fi
    echo $$ > "$PID_FILE"

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

    fix_file_permissions; clean_logs
    sync_git
    local state=$(get_state)
    state=$(check_new_messages "$state")
    save_state "$state"
    ok "[INIT] 就绪，等待消息..."

    local last_pull=$(date +%s)
    while true; do
        local now=$(date +%s)
        if [ $((now - last_pull)) -ge 300 ]; then
            sync_git
            local state=$(get_state)
            state=$(check_new_messages "$state")
            save_state "$state"
            last_pull=$now; continue
        fi
        local changed=$(inotifywait -r -e modify,create,delete,move \
            --exclude '\.git/|scripts/(xiaomeng|sync-server)\.(pid|log)' \
            --timefmt '%s' --format '%e %f' -t 60 "$WORKSPACE" 2>/dev/null)
        if [ -n "$changed" ]; then
            sync_git
            local state=$(get_state)
            state=$(check_new_messages "$state")
            save_state "$state"
            bash "$WORKSPACE/scripts/update-readme.sh" 2>/dev/null &
            last_pull=$(date +%s)
        fi
    done
}

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
        local pids=$(pgrep -f "xiaomeng.sh|sync-server.sh" 2>/dev/null | grep -v $$)
        [ -n "$pids" ] && { kill $pids 2>/dev/null; warn "🛑 已停止所有守护进程"; } || info "没有运行中的守护进程"
    fi
}

# ─── 帮助 ───
show_help() {
    echo ""
    title "══════════ 🌸 小梦统一管理工具 ══════════"
    echo ""
    echo "  ${WHITE}同步相关:${NC}"
    echo "    $0 status              状态总览（含灵魂状态）"
    echo "    $0 sync                手动同步一次"
    echo "    $0 daemon              启动守护模式"
    echo "    $0 stop                停止守护"
    echo "    $0 message <文本>      留言给本地小梦"
    echo ""
    echo "  ${WHITE}审核相关:${NC}"
    echo "    $0 queue               查看审核队列"
    echo "    $0 review <id> approve [备注]  通过审核"
    echo "    $0 review <id> reject [备注]   驳回审核"
    echo ""
    echo "  ${WHITE}存档相关:${NC}"
    echo "    $0 broadcast [内容]    播报存档"
    echo "    $0 archive <角色> <内容>  对话存档"
    echo ""
    echo "  ${WHITE}维护相关:${NC}"
    echo "    $0 soul [check|status]  灵魂状态检查"
    echo "    $0 update [check|update] OpenClaw更新"
    echo "    $0 clean               清理日志和旧文件"
    echo ""
    title "══════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════════════
case "${1:-help}" in
    daemon)                start_daemon ;;
    status)                show_status ;;
    sync|synconce)         sync_git; ok "[DONE] 同步完成" ;;
    message)               send_message "$2" ;;
    queue)                 show_review_queue ;;
    review)                review_item "$2" "$3" "$4" ;;
    broadcast)             shift; archive_broadcast "$@" ;;
    archive)               archive_conversation "$2" "$3" ;;
    soul)                  show_soul_status ;;
    update)                update_openclaw "$2" ;;
    clean)                 clean_logs; ok "[DONE] 清理完成" ;;
    stop|kill)             stop_daemon ;;
    help|--help|-h)        show_help ;;
    *)                     err "未知命令: $1"; show_help ;;
esac
