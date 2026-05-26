#!/bin/bash
# 看门狗 - 确保 sync daemon 运行（只保留一个实例）
pgrep -f "sync-server\.sh (daemon|$)" | grep -v "$$\|$(pgrep -f 'watchdog\.sh' | head -1)" > /dev/null || {
    cd /home/admin/.openclaw/workspace
    nohup bash scripts/sync-server.sh daemon >> scripts/sync-server-cron.log 2>&1 &
}
