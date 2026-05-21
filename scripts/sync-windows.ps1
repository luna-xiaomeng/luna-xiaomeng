<#
.SYNOPSIS
    小梦记忆双向同步守护脚本 (Windows)
.DESCRIPTION
    • 实时监控文件变更 → 自动 git push 到 Gitee
    • 每 20 秒 git pull ← 拉取服务器/别处的更新
    • 防抖 + 防循环，安心挂后台
#>

param()

$workspace   = Join-Path $env:USERPROFILE ".openclaw\workspace"
$logFile     = Join-Path $workspace "scripts\sync-windows.log"
$pidFile     = Join-Path $workspace "scripts\sync-windows.pid"

# ─── 日志 ───
function Write-Log {
    param([string]$Msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time | $Msg" | Out-File -FilePath $logFile -Append -Encoding utf8
    Write-Host "$time | $Msg"
}

# ─── 防重复 ───
if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile -Raw | ForEach-Object { $_.Trim() }
    if ($oldPid -and (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)) {
        Write-Log "⚠️ 已在运行 (PID: $oldPid)，退出"
        exit 0
    }
}
$pid.ToString() | Out-File -FilePath $pidFile -Encoding utf8

# ─── 全局锁 ───
$global:syncing = $false
$global:dirty   = $false
$global:debounceTimer = $null

# ─── Git 同步（pull + push） ───
function Invoke-GitSync {
    if ($global:syncing) { return }
    $global:syncing = $true
    $global:dirty   = $false

    try {
        Push-Location $workspace

        # Step 1: Pull 远程
        $pullOut = git pull --rebase --autostash 2>&1
        $pullStr = "$pullOut"
        if ($LASTEXITCODE -ne 0) {
            # rebase 冲突？
            git merge --abort 2>$null
            $pullOut2 = git pull --no-rebase --autostash 2>&1
            Write-Log "⚠️ Pull (no-rebase): $pullOut2"
        } elseif ($pullStr -notmatch "Already up to date") {
            Write-Log "⬇️ Pull 到更新: $(($pullStr -split "`n").Count) 行"
        }

        # Step 2: 检查本地变更 → Push
        $status = git status --porcelain 2>&1
        if ($status) {
            git add -A 2>&1 | Out-Null
            git commit -m "🔄 自动同步 $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>&1 | Out-Null
            $pushOut = git push origin main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "⬆️ Push 成功 ($(@($status)).Count 文件变更)"
            } else {
                Write-Log "❌ Push 失败: $pushOut"
            }
        }

        Pop-Location
    } catch {
        Write-Log "❌ Git 异常: $_"
    } finally {
        $global:syncing = $false
    }
}

# ─── 防抖触发 ───
function On-Change {
    if ($global:syncing) { return }
    $global:dirty = $true

    if ($global:debounceTimer) {
        $global:debounceTimer.Stop()
        $global:debounceTimer.Dispose()
    }

    $global:debounceTimer = New-Object System.Timers.Timer
    $global:debounceTimer.Interval = 5000
    $global:debounceTimer.AutoReset = $false
    Register-ObjectEvent -InputObject $global:debounceTimer -EventName Elapsed -Action {
        Invoke-GitSync
    } | Out-Null
    $global:debounceTimer.Start()
}

# ─── 文件监控 ───
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path          = $workspace
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter  = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::DirectoryName
$watcher.Filter        = "*.*"
$watcher.EnableRaisingEvents = $true

$changeAction = {
    $path = $EventArgs.FullPath
    if ($path -match '\\.git[\\/]')  { return }   # 忽略 .git
    if ($path -match '\\scripts[\\/]') { return }  # 忽略脚本自身
    if ($path -match '\\.log$')      { return }    # 忽略日志
    On-Change
}

Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $changeAction | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $changeAction | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $changeAction | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Renamed  -Action $changeAction | Out-Null

# ─── 定时 Pull（20秒间隔） ───
$pullTimer = New-Object System.Timers.Timer
$pullTimer.Interval = 20000
$pullTimer.AutoReset = $true
Register-ObjectEvent -InputObject $pullTimer -EventName Elapsed -Action {
    if (-not $global:syncing -and -not $global:dirty) {
        Invoke-GitSync
    }
} | Out-Null
$pullTimer.Start()

Write-Log "🚀 小梦双向同步守护启动"
Write-Log "📁  $workspace"
Write-Log "🔗  $(git -C $workspace remote get-url origin 2>&1)"
Write-Log "✅ 等待文件变更..."

# ─── 保持运行 ───
while ($true) {
    Start-Sleep -Seconds 10
}
