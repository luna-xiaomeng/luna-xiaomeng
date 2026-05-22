@echo off
REM 小梦记忆自动同步脚本 - 每30分钟由计划任务调用
cd /d C:\Users\Administrator\.openclaw\workspace
git add -A
git -c credential.helper= commit -m "🔄 自动同步" --allow-empty 2> nul
git -c credential.helper= push origin master 2> nul
