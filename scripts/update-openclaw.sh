#!/bin/bash
# OpenClaw 自动更新脚本（Linux / 云端版）
# 用法: bash scripts/update-openclaw.sh [check|update|auto]

WORKSPACE_DIR="/home/admin/.openclaw/workspace"
LOG_FILE="${WORKSPACE_DIR}/scripts/update-log.txt"
ACTION="${1:-check}"
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# Get current
current=$(openclaw --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+')
[ -z "$current" ] && current="未知"

# Get latest
data=$(curl -s https://api.github.com/repos/openclaw/openclaw/releases/latest 2>/dev/null)
latest=$(echo "$data" | grep -oP '(?<=tag_name": "v)\d+\.\d+\.\d+')
release_url=$(echo "$data" | grep -oP 'https://github[^"]+')
[ -z "$latest" ] && latest="获取失败"

echo ""
echo "========================================"
echo "  OpenClaw 版本检测"
echo "  当前: v$current"
echo "  最新: v$latest"
echo "========================================"

[ "$latest" = "获取失败" ] && { echo "! 无法联网"; exit 1; }

needs_update=false
if [ "$current" != "未知" ]; then
    IFS='.' read -ra c <<< "$current"
    IFS='.' read -ra l <<< "$latest"
    for i in 0 1 2; do
        if [ "${l[$i]}" -gt "${c[$i]}" 2>/dev/null ]; then needs_update=true; break; fi
        if [ "${l[$i]}" -lt "${c[$i]}" 2>/dev/null ]; then break; fi
    done
fi

if [ "$needs_update" = false ]; then
    echo -e "\n  [OK] 已是最新版本"
    echo "$NOW | OK: v$current" >> "$LOG_FILE"
    exit 0
fi

echo -e "\n  [!!] 发现新版本 v$latest!"
echo "  $release_url"

if [ "$ACTION" = "check" ]; then
    echo -e "\n  运行 bash scripts/update-openclaw.sh update 升级"
    exit 0
fi

if [ "$ACTION" = "update" ] || [ "$ACTION" = "auto" ]; then
    echo -e "\n  正在升级..."
    npm install -g openclaw@latest 2>/dev/null
    new_ver=$(openclaw --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+')
    echo "  升级完成: v$new_ver"
    echo "$NOW | 升级: v$current -> v$new_ver" >> "$LOG_FILE"
    echo -e "\n  建议重启: openclaw gateway restart"
fi
