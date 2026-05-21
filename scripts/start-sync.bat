@echo off
REM =============================================
REM 小梦记忆双向同步 - 启动器
REM 开机自动启动同步守护进程（无窗口后台运行）
REM =============================================

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%sync-windows.ps1

REM 启动 PowerShell 脚本（隐藏窗口）
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
