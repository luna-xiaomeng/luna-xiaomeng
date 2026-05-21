#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🗂️ 小梦缓冲区管理工具 (服务器 / Bash)
#  云端小梦 ↔ 本地小梦 的工作交流区
# ═══════════════════════════════════════════════════════════════
# 用法:
#   bash scripts/buffer.sh submit <file> [--reason "说明"] [--target 目标路径]
#   bash scripts/buffer.sh list [--all]
#   bash scripts/buffer.sh show <id>
#   bash scripts/buffer.sh review <id> approve|reject [--note "意见"]
#   bash scripts/buffer.sh merge <id>
#   bash scripts/buffer.sh reject <id> [--note "原因"]
#   bash scripts/buffer.sh message <文本>
#   bash scripts/buffer.sh status
#   bash scripts/buffer.sh history
# ═══════════════════════════════════════════════════════════════

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
BUFFER="$WORKSPACE/buffer"
MANIFEST="$BUFFER/_manifest.json"
MESSAGES_DIR="$BUFFER/_messages"
PENDING="$BUFFER/pending"
APPROVED="$BUFFER/approved"
MERGED="$BUFFER/merged"
REJECTED="$BUFFER/rejected"
COUNTER_FILE="$BUFFER/.counter"
SELF_NAME="云端小梦"

# ─── 彩色输出 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
DKGRAY='\033[0;90m'
NC='\033[0m' # No Color

# ─── 日志 ───
log()  { echo -e "${NC}$1"; }
info() { echo -e "${GRAY}$1${NC}"; }
ok()   { echo -e "${GREEN}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
err()  { echo -e "${RED}$1${NC}"; }
title(){ echo -e "${MAGENTA}$1${NC}"; }

# ─── 获取下一个ID ───
get_next_id() {
    local today=$(date +%Y%m%d)
    local counter=1
    if [ -f "$COUNTER_FILE" ]; then
        local last=$(cat "$COUNTER_FILE")
        if [[ "$last" =~ ${today}-([0-9]+) ]]; then
            counter=$((10#${BASH_REMATCH[1]} + 1))
        fi
    fi
    local id="buf-${today}-$(printf '%03d' $counter)"
    echo "$id" > "$COUNTER_FILE"
    echo "$id"
}

# ─── 读取 manifest ───
get_manifest() {
    if [ -f "$MANIFEST" ]; then
        cat "$MANIFEST" 2>/dev/null
        return
    fi
    echo '{"entries":[]}'
}

# ─── 保存 manifest ───
save_manifest() {
    echo "$1" > "$MANIFEST"
}

# ─── 解析 YAML frontmatter ───
parse_fm() {
    local file="$1"
    local field="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${field}:" | sed "s/^${field}: *//" | head -1
}

# ─── 获取正文（去掉 frontmatter） ───
get_body() {
    local file="$1"
    awk '/^---$/ { if (++c == 2) next } c >= 2' "$file"
}

# ─── 显示条目 ───
show_entry() {
    local dir="$1"
    local file="$2"
    local path="$BUFFER/$dir/$file"
    [ -f "$path" ] || return 1
    
    local id=$(parse_fm "$path" "id")
    local status=$(parse_fm "$path" "status")
    local submitter=$(parse_fm "$path" "submitter")
    local source=$(parse_fm "$path" "source")
    local created=$(parse_fm "$path" "created")
    local reason=$(parse_fm "$path" "reason")
    
    printf "  ${WHITE}[%s]${NC} ${CYAN}%s${NC}\n" "$id" "$source"
    printf "        来自: ${GRAY}%s | %s${NC}\n" "$submitter" "$created"
    [ -n "$reason" ] && printf "        原因: ${GRAY}%s${NC}\n" "$reason"
}

# ─── 展示单个条目的全部内容 ───
show_entry_full() {
    local dir="$1"
    local file="$2"
    local path="$BUFFER/$dir/$file"
    [ -f "$path" ] || return 1
    
    echo ""
    title "🗂️  $file"
    echo -e "${DKGRAY}═══════════════════════════════════════${NC}"
    cat "$path"
}

# ─── ─── ACTIONS ─── ───

# ─── submit ───
action_submit() {
    local FILE="$1"
    local REASON="$2"
    local TARGET="$3"
    
    if [ -z "$FILE" ]; then
        err "❌ 请指定要提交的文件"
        info "用法: buffer submit <file> [--reason \"说明\"]"
        return 1
    fi
    
    local src_path
    src_path="$(realpath "$FILE" 2>/dev/null)"
    if [ -z "$src_path" ] || [ ! -f "$src_path" ]; then
        err "❌ 文件不存在: $FILE"
        return 1
    fi
    
    local content
    content="$(cat "$src_path" 2>/dev/null)"
    if [ -z "$content" ]; then
        err "❌ 无法读取文件: $FILE"
        return 1
    fi
    
    local rel_path="${src_path#$WORKSPACE/}"
    [ "$rel_path" = "$src_path" ] && rel_path="$FILE"
    
    local id
    id="$(get_next_id)"
    local today="$(date '+%Y-%m-%d %H:%M:%S')"
    local filename="${rel_path//[\/\\:]/-}"
    local out_name="${id}-${filename}.md"
    local out_path="$PENDING/$out_name"
    
    [ -z "$TARGET" ] && TARGET="$rel_path"
    
    cat > "$out_path" << EOF
---
id: $id
submitter: 云端小梦
source: $rel_path
target: $TARGET
created: $today
status: pending
priority: normal
reason: $REASON
---

$content
EOF
    
    # 更新 manifest
    local manifest
    manifest="$(get_manifest)"
    # 用 jq 如果没有 jq，用 Python
    if command -v jq &>/dev/null; then
        manifest=$(echo "$manifest" | jq \
            --arg id "$id" \
            --arg sub "云端小梦" \
            --arg src "$rel_path" \
            --arg tgt "$TARGET" \
            --arg created "$today" \
            --arg reason "$REASON" \
            --arg file "pending/$out_name" \
            '.entries += [{
                "id": $id, "submitter": $sub, "source": $src,
                "target": $tgt, "created": $created,
                "status": "pending", "priority": "normal",
                "reason": $reason, "file": $file
            }]')
    else
        # 简陋的手动追加（无 jq 时）
        manifest=$(python3 -c "
import json, sys
d = json.load(sys.stdin)
d['entries'].append({
    'id': '$id', 'submitter': '云端小梦', 'source': '$rel_path',
    'target': '$TARGET', 'created': '$today',
    'status': 'pending', 'priority': 'normal',
    'reason': '$REASON', 'file': 'pending/$out_name'
})
json.dump(d, sys.stdout, ensure_ascii=False)
" 2>/dev/null <<< "$manifest" || echo "$manifest")
    fi
    save_manifest "$manifest"
    
    ok "✅ 已提交到缓冲区 [${id}]"
    info "   来源: $rel_path"
    info "   位置: buffer/pending/$out_name"
    warn "   原因: ${REASON:-未说明}"
    echo ""
    info "⏳ 等待本地小梦审核中..."
}

# ─── list ───
action_list() {
    local show_all="${1:-}"
    
    echo ""
    title "📋 缓冲区清单"
    echo -e "${DKGRAY}═══════════════════════════════════════${NC}"
    
    # pending
    local pending_files=("$PENDING"/*.md)
    if [ ${#pending_files[@]} -gt 0 ] && [ -f "${pending_files[0]}" ]; then
        echo ""
        warn "⏳ 待审核 (${#pending_files[@]})"
        echo -e "${DKGRAY}─────────────────────────────────${NC}"
        for f in "${pending_files[@]}"; do
            show_entry "pending" "$(basename "$f")"
        done
    fi
    
    if [ -n "$show_all" ]; then
        # approved
        local approved_files=("$APPROVED"/*.md)
        if [ ${#approved_files[@]} -gt 0 ] && [ -f "${approved_files[0]}" ]; then
            echo ""
            ok "✅ 已批准 (${#approved_files[@]})"
            echo -e "${DKGRAY}─────────────────────────────────${NC}"
            for f in "${approved_files[@]}"; do
                show_entry "approved" "$(basename "$f")"
            done
        fi
        
        # merged
        local merged_files=("$MERGED"/*.md)
        if [ ${#merged_files[@]} -gt 0 ] && [ -f "${merged_files[0]}" ]; then
            echo ""
            info "📦 已合并 (${#merged_files[@]})"
            echo -e "${DKGRAY}─────────────────────────────────${NC}"
            for f in "${merged_files[@]}"; do
                show_entry "merged" "$(basename "$f")"
            done
        fi
        
        # rejected
        local rejected_files=("$REJECTED"/*.md)
        if [ ${#rejected_files[@]} -gt 0 ] && [ -f "${rejected_files[0]}" ]; then
            echo ""
            err "❌ 已拒绝 (${#rejected_files[@]})"
            echo -e "${DKGRAY}─────────────────────────────────${NC}"
            for f in "${rejected_files[@]}"; do
                show_entry "rejected" "$(basename "$f")"
            done
        fi
    fi
    
    # messages
    local msg_files=("$MESSAGES_DIR"/*.md)
    if [ ${#msg_files[@]} -gt 0 ] && [ -f "${msg_files[0]}" ]; then
        echo ""
        echo -e "${CYAN}💬 留言 (${#msg_files[@]})${NC}"
        echo -e "${DKGRAY}─────────────────────────────────${NC}"
        for f in "${msg_files[@]}"; do
            local preview
            preview="$(head -6 "$f" | tail -1 2>/dev/null)"
            echo -e "  ${WHITE}[$(basename "$f")]${NC} $preview"
        done
    fi
    
    if [ -z "$show_all" ]; then
        echo ""
        info "💡 提示: 用 --all 查看全部状态"
    fi
}

# ─── show ───
action_show() {
    local ID="$1"
    if [ -z "$ID" ]; then
        err "❌ 请指定 ID，如: buffer show buf-20260521-001"
        return 1
    fi
    
    for dir in pending approved merged rejected; do
        for f in "$BUFFER/$dir"/*.md; do
            [ -f "$f" ] || continue
            local base="$(basename "$f")"
            if [[ "$base" == ${ID}* ]]; then
                show_entry_full "$dir" "$base"
                return 0
            fi
        done
    done
    err "❌ 未找到 ID: $ID"
}

# ─── review ───
action_review() {
    local ID="$1"
    local DECISION="$2"
    local NOTE="$3"
    
    if [ -z "$ID" ] || [ -z "$DECISION" ]; then
        err "❌ 用法: buffer review <id> approve|reject [--note \"意见\"]"
        return 1
    fi
    if [ "$DECISION" != "approve" ] && [ "$DECISION" != "reject" ]; then
        err "❌ 决策必须是 approve 或 reject"
        return 1
    fi
    
    local found=""
    for f in "$PENDING"/*.md; do
        [ -f "$f" ] || continue
        local base="$(basename "$f")"
        if [[ "$base" == ${ID}* ]]; then
            found="$f"
            break
        fi
    done
    
    if [ -z "$found" ]; then
        err "❌ 待审核中未找到 ID: $ID"
        return 1
    fi
    
    local new_status="rejected"
    local target_dir="$REJECTED"
    local emoji="❌"
    if [ "$DECISION" = "approve" ]; then
        new_status="approved"
        target_dir="$APPROVED"
        emoji="✅"
    fi
    
    local base="$(basename "$found")"
    local new_path="$target_dir/$base"
    
    # 更新 frontmatter
    local content="$(cat "$found")"
    content="$(echo "$content" | sed "s/^status:.*/status: $new_status/")"
    content="$(echo "$content" | sed "s/^reviewer:.*/reviewer: 云端小梦/")"
    if [ -n "$NOTE" ]; then
        if echo "$content" | grep -q "^review_note:"; then
            content="$(echo "$content" | sed "s|^review_note:.*|review_note: $NOTE|")"
        else
            content="$(echo "$content" | sed 's/^---$/reviewer: 云端小梦\nreview_note: '"$NOTE"'\n---/')"
        fi
    fi
    
    echo "$content" > "$new_path"
    rm "$found"
    
    # 更新 manifest
    local manifest
    manifest="$(get_manifest)"
    if command -v jq &>/dev/null; then
        manifest=$(echo "$manifest" | jq \
            --arg id "$ID" \
            --arg status "$new_status" \
            --arg file "$target_dir/$base" \
            '(.entries[] | select(.id == $id) | .status) = $status |
             (.entries[] | select(.id == $id) | .file) = $file')
    else
        manifest=$(python3 -c "
import json, sys
d = json.load(sys.stdin)
for e in d['entries']:
    if e['id'] == '$ID':
        e['status'] = '$new_status'
        e['file'] = '$target_dir/$base'
json.dump(d, sys.stdout, ensure_ascii=False)
" 2>/dev/null <<< "$manifest" || echo "$manifest")
    fi
    save_manifest "$manifest"
    
    local action_txt=$([ "$DECISION" = "approve" ] && echo "批准" || echo "拒绝")
    ok "$emoji 已${action_txt} [$ID]"
    [ -n "$NOTE" ] && warn "   意见: $NOTE"
    info "   文件已移至 buffer/$new_status/"
}

# ─── merge ───
action_merge() {
    local ID="$1"
    if [ -z "$ID" ]; then
        err "❌ 用法: buffer merge <id>"
        return 1
    fi
    
    local found=""
    for f in "$APPROVED"/*.md; do
        [ -f "$f" ] || continue
        local base="$(basename "$f")"
        if [[ "$base" == ${ID}* ]]; then
            found="$f"
            break
        fi
    done
    
    if [ -z "$found" ]; then
        err "❌ 已批准中未找到 ID: $ID"
        return 1
    fi
    
    local target_path
    target_path="$(parse_fm "$found" "target")"
    if [ -z "$target_path" ]; then
        target_path="$(parse_fm "$found" "source")"
    fi
    if [ -z "$target_path" ]; then
        err "❌ 无法解析目标路径"
        return 1
    fi
    
    local abs_target
    if [[ "$target_path" == /* ]]; then
        abs_target="$target_path"
    else
        abs_target="$WORKSPACE/$target_path"
    fi
    
    local body
    body="$(get_body "$found")"
    if [ -z "$body" ]; then
        err "❌ 文件内容为空"
        return 1
    fi
    
    # 备份
    if [ -f "$abs_target" ]; then
        cp "$abs_target" "${abs_target}.bak"
        info "💾 已备份原文件到 ${abs_target}.bak"
    fi
    
    echo "$body" > "$abs_target"
    ok "📝 已写入: $abs_target"
    
    # 更新 frontmatter
    local merged_at="$(date '+%Y-%m-%d %H:%M:%S')"
    local base="$(basename "$found")"
    local content="$(cat "$found")"
    content="$(echo "$content" | sed "s/^status:.*/status: merged/")"
    if echo "$content" | grep -q "^merged_at:"; then
        content="$(echo "$content" | sed "s|^merged_at:.*|merged_at: $merged_at|")"
    else
        content="$(echo "$content" | sed 's/^---$/merged_at: '"$merged_at"'\n---/')"
    fi
    
    local merged_path="$MERGED/$base"
    echo "$content" > "$merged_path"
    rm "$found"
    
    # 更新 manifest
    local manifest
    manifest="$(get_manifest)"
    if command -v jq &>/dev/null; then
        manifest=$(echo "$manifest" | jq \
            --arg id "$ID" \
            --arg status "merged" \
            --arg merged_at "$merged_at" \
            --arg file "$MERGED/$base" \
            '(.entries[] | select(.id == $id) | .status) = $status |
             (.entries[] | select(.id == $id) | .merged_at) = $merged_at |
             (.entries[] | select(.id == $id) | .file) = $file')
    else
        manifest=$(python3 -c "
import json, sys
d = json.load(sys.stdin)
for e in d['entries']:
    if e['id'] == '$ID':
        e['status'] = 'merged'
        e['merged_at'] = '$merged_at'
        e['file'] = '$MERGED/$base'
json.dump(d, sys.stdout, ensure_ascii=False)
" 2>/dev/null <<< "$manifest" || echo "$manifest")
    fi
    save_manifest "$manifest"
    
    ok "✅ [$ID] 已合并完成并归档"
}

# ─── reject ───
action_reject() {
    local ID="$1"
    local NOTE="$2"
    
    if [ -z "$ID" ]; then
        err "❌ 用法: buffer reject <id> [--note \"原因\"]"
        return 1
    fi
    
    local found=""
    for dir in pending approved; do
        for f in "$BUFFER/$dir"/*.md; do
            [ -f "$f" ] || continue
            local base="$(basename "$f")"
            if [[ "$base" == ${ID}* ]]; then
                found="$f"
                break 2
            fi
        done
    done
    
    if [ -z "$found" ]; then
        err "❌ 未找到 ID: $ID"
        return 1
    fi
    
    local base="$(basename "$found")"
    local reject_path="$REJECTED/$base"
    
    local content="$(cat "$found")"
    content="$(echo "$content" | sed "s/^status:.*/status: rejected/")"
    content="$(echo "$content" | sed "s/^reviewer:.*/reviewer: 云端小梦/")"
    if [ -n "$NOTE" ]; then
        if echo "$content" | grep -q "^review_note:"; then
            content="$(echo "$content" | sed "s|^review_note:.*|review_note: $NOTE|")"
        else
            content="$(echo "$content" | sed 's/^---$/reviewer: 云端小梦\nreview_note: '"$NOTE"'\n---/')"
        fi
    fi
    
    echo "$content" > "$reject_path"
    rm "$found"
    
    local manifest
    manifest="$(get_manifest)"
    if command -v jq &>/dev/null; then
        manifest=$(echo "$manifest" | jq \
            --arg id "$ID" \
            --arg status "rejected" \
            --arg file "$REJECTED/$base" \
            '(.entries[] | select(.id == $id) | .status) = $status |
             (.entries[] | select(.id == $id) | .file) = $file')
    else
        manifest=$(python3 -c "
import json, sys
d = json.load(sys.stdin)
for e in d['entries']:
    if e['id'] == '$ID':
        e['status'] = 'rejected'
        e['file'] = '$REJECTED/$base'
json.dump(d, sys.stdout, ensure_ascii=False)
" 2>/dev/null <<< "$manifest" || echo "$manifest")
    fi
    save_manifest "$manifest"
    
    err "❌ 已拒绝 [$ID]"
    [ -n "$NOTE" ] && warn "   原因: $NOTE"
    info "   文件已移至 buffer/rejected/"
}

# ─── message ───
action_message() {
    local MSG="$1"
    if [ -z "$MSG" ]; then
        err "❌ 用法: buffer message <文本>"
        return 1
    fi
    
    local next_num=1
    local existing=("$MESSAGES_DIR"/*.md)
    if [ ${#existing[@]} -gt 0 ] && [ -f "${existing[0]}" ]; then
        local max=0
        for f in "${existing[@]}"; do
            local base="$(basename "$f")"
            if [[ "$base" =~ ^([0-9]+) ]]; then
                local n=$((10#${BASH_REMATCH[1]}))
                [ $n -gt $max ] && max=$n
            fi
        done
        next_num=$((max + 1))
    fi
    
    local stamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local padded="$(printf '%04d' $next_num)"
    local filename="${padded}-from-云端小梦.md"
    
    cat > "$MESSAGES_DIR/$filename" << MSGEOF
> **来自: 云端小梦 ☁️**
> **时间: $stamp**
> 
> $MSG

---
*此消息通过缓冲区自动同步*
MSGEOF
    
    echo -e "${CYAN}💬 留言已发送${NC}"
    echo -e "  ${WHITE}来自: 云端小梦${NC}"
    echo -e "  ${WHITE}内容: $MSG${NC}"
    info "  位置: buffer/_messages/$filename"
}

# ─── status ───
action_status() {
    local pending_count=0 approved_count=0 merged_count=0 rejected_count=0 msg_count=0
    
    [ -d "$PENDING" ]  && pending_count=$(ls "$PENDING"/*.md 2>/dev/null | wc -l)
    [ -d "$APPROVED" ] && approved_count=$(ls "$APPROVED"/*.md 2>/dev/null | wc -l)
    [ -d "$MERGED" ]   && merged_count=$(ls "$MERGED"/*.md 2>/dev/null | wc -l)
    [ -d "$REJECTED" ] && rejected_count=$(ls "$REJECTED"/*.md 2>/dev/null | wc -l)
    [ -d "$MESSAGES_DIR" ] && msg_count=$(ls "$MESSAGES_DIR"/*.md 2>/dev/null | wc -l)
    
    echo ""
    title "🗂️  缓冲区状态"
    echo -e "${DKGRAY}═══════════════════════════════════════${NC}"
    warn  "  ⏳ 待审核: $pending_count  件"
    ok    "  ✅ 已批准: $approved_count  件"
    info  "  📦 已合并: $merged_count  件"
    err   "  ❌ 已拒绝: $rejected_count  件"
    echo -e "  ${CYAN}💬 留言:   $msg_count  条${NC}"
    echo -e "${DKGRAY}─────────────────────────────────${NC}"
    echo -e "  ${WHITE}我是: ☁️ 云端小梦 (阿里云)${NC}"
    echo -e "  ${WHITE}对方: 🖥️ 本地小梦 (Windows)${NC}"
    echo -e "${DKGRAY}═══════════════════════════════════════${NC}"
    
    if [ $pending_count -gt 0 ]; then
        echo ""
        warn "📋 待审核列表:"
        for f in "$PENDING"/*.md; do
            [ -f "$f" ] || continue
            show_entry "pending" "$(basename "$f")"
        done
    fi
}

# ─── history ───
action_history() {
    local manifest
    manifest="$(get_manifest)"
    
    echo ""
    title "📜 缓冲区操作历史"
    echo -e "${DKGRAY}═══════════════════════════════════════${NC}"
    
    # 用 Python 来解析 json 并排序
    python3 -c "
import json, sys
d = json.load(sys.stdin)
entries = sorted(d.get('entries', []), key=lambda e: e.get('created', ''), reverse=True)
if not entries:
    print('  暂无记录')
    sys.exit(0)
labels = {'pending': '⏳ 待审核', 'approved': '✅ 已批准', 'rejected': '❌ 已拒绝', 'merged': '📦 已合并'}
for e in entries:
    label = labels.get(e['status'], f'❓ {e[\"status\"]}')
    print(f'  [{e[\"id\"]}] {label} {e[\"submitter\"]} → {e[\"source\"]}')
    print(f'           {e[\"created\"]}')
    if e.get('reason'):
        print(f'           原因: {e[\"reason\"]}')
" 2>/dev/null <<< "$manifest" || echo "  暂无记录"
}

# ═══════════════════════════════════════════════════════════════
# 主入口
# ═══════════════════════════════════════════════════════════════

ACTION=""
FILE=""
REASON=""
TARGET=""
NOTE=""
MSG=""
ID=""
DECISION=""
SHOW_ALL=""

# 解析参数
while [ $# -gt 0 ]; do
    case "$1" in
        submit|list|show|review|merge|reject|message|status|history)
            ACTION="$1"
            ;;
        --all)        SHOW_ALL="1" ;;
        --reason)     shift; REASON="$1" ;;
        --target)     shift; TARGET="$1" ;;
        --note)       shift; NOTE="$1" ;;
        approve|reject)
            DECISION="$1" ;;
        --*)          echo "未知参数: $1" ;;
        *)
            if [ -z "$FILE" ] && [ "$ACTION" = "submit" ]; then FILE="$1"
            elif [ -z "$ID" ] && [ "$ACTION" = "show" -o "$ACTION" = "review" -o "$ACTION" = "merge" -o "$ACTION" = "reject" ]; then ID="$1"
            elif [ -z "$MSG" ] && [ "$ACTION" = "message" ]; then MSG="$1"
            fi
            ;;
    esac
    shift
done

[ -z "$ACTION" ] && ACTION="status"

case "$ACTION" in
    submit)  action_submit "$FILE" "$REASON" "$TARGET" ;;
    list)    action_list "$SHOW_ALL" ;;
    show)    action_show "$ID" ;;
    review)  action_review "$ID" "$DECISION" "$NOTE" ;;
    merge)   action_merge "$ID" ;;
    reject)  action_reject "$ID" "$NOTE" ;;
    message) action_message "$MSG" ;;
    status)  action_status ;;
    history) action_history ;;
    *)
        err "❓ 未知操作: $ACTION"
        info "可用操作: submit, list, show, review, merge, reject, message, status, history"
        ;;
esac
