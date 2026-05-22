#!/bin/bash
# 看门狗 - 确保 sync daemon 运行
pgrep -f "sync-server.sh daemon" > /dev/null || {
    cd /home/admin/.openclaw/workspace
    nohup bash scripts/sync-server.sh daemon >> scripts/sync-server-cron.log 2>&1 &
}
