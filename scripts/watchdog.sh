#!/bin/bash
PID_FILE="/root/.openclaw/workspace/scripts/sync-server.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
fi
# PID文件不存在或进程已死，启动新�?
cd /root/.openclaw/workspace || exit 1
nohup bash scripts/sync-server.sh daemon >> scripts/sync-server-cron.log 2>&1 &
