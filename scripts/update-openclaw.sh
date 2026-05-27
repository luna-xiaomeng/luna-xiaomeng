#!/bin/bash
# OpenClaw Auto Update Script v2.1 (Linux / Cloud)
# Fixes: missing bundled deps -> npm install repair -> service restart
# Usage: bash scripts/update-openclaw.sh [check|update|auto]

WORKSPACE_DIR="/root/.openclaw/workspace"
LOG_FILE="${WORKSPACE_DIR}/scripts/update-log.txt"
ACTION="${1:-check}"
NOW=$(date '+%Y-%m-%d %H:%M:%S')

get_version() {
    openclaw --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+'
}

install_deps() {
    echo "  Installing bundled dependencies..."
    local dir
    dir=$(dirname "$(readlink -f "$(which openclaw)")" 2>/dev/null || npm root -g 2>/dev/null)/openclaw
    if [ -d "$dir" ]; then
        cd "$dir" && npm install 2>/dev/null
        # Check and install specific missing packages
        if ! ls node_modules/@earendil-works 2>/dev/null | grep -q pi-coding-agent; then
            echo "  Installing missing pi packages..."
            npm install @earendil-works/pi-coding-agent @earendil-works/pi-agent-core @earendil-works/pi-ai @earendil-works/pi-tui 2>/dev/null
        fi
    fi
}

repair_and_restart() {
    echo "  Repairing gateway service..."
    local out
    out=$(openclaw gateway start 2>&1)
    if echo "$out" | grep -qiE "repaired|started|running"; then
        echo "  Gateway started successfully"
        return 0
    fi
    out=$(openclaw gateway restart 2>&1)
    if echo "$out" | grep -qiE "repaired|started|running|ok"; then
        echo "  Gateway restarted successfully"
        return 0
    fi
    return 1
}

# Main
current=$(get_version)
[ -z "$current" ] && current="N/A"

data=$(curl -s https://api.github.com/repos/openclaw/openclaw/releases/latest 2>/dev/null)
latest=$(echo "$data" | grep -oP '(?<=tag_name": "v)\d+\.\d+\.\d+')
release_url=$(echo "$data" | grep -oP 'https://github[^"]+')
[ -z "$latest" ] && latest="ERR"

echo ""
echo "==========================="
echo " OpenClaw Auto Update v2.1"
echo " Current: v$current"
echo " Latest:  v$latest"
echo "==========================="

[ "$latest" = "ERR" ] && { echo " Cannot check latest"; exit 1; }

needs_update=false
if [ "$current" != "N/A" ]; then
    IFS='.' read -ra c <<< "$current"
    IFS='.' read -ra l <<< "$latest"
    for i in 0 1 2; do
        [ "${l[$i]}" -gt "${c[$i]}" 2>/dev/null ] && { needs_update=true; break; }
        [ "${l[$i]}" -lt "${c[$i]}" 2>/dev/null ] && break
    done
fi

if [ "$needs_update" = false ]; then
    echo -e "\n [OK] v$current is latest"
    echo "$NOW | OK: v$current" >> "$LOG_FILE"
    exit 0
fi

echo -e "\n [!!] New version v$latest!"

if [ "$ACTION" = "check" ]; then
    echo " Run: bash scripts/update-openclaw.sh update"
    exit 0
fi

if [ "$ACTION" = "update" ] || [ "$ACTION" = "auto" ]; then
    echo -e "\n === Step 1: npm global upgrade ==="
    npm install -g openclaw@latest 2>/dev/null
    new_ver=$(get_version)
    echo " CLI version: v$new_ver"
    
    echo -e "\n === Step 2: Install bundled deps ==="
    install_deps
    
    echo -e "\n === Step 3: Repair + restart gateway ==="
    if repair_and_restart; then
        echo -e "\n [OK] Upgrade: v$current -> v$new_ver"
        echo "$NOW | OK: v$current -> v$new_ver" >> "$LOG_FILE"
    else
        echo -e "\n [!!] Manual restart needed: openclaw gateway start"
        echo "$NOW | PARTIAL: v$current -> v$new_ver" >> "$LOG_FILE"
    fi
fi
