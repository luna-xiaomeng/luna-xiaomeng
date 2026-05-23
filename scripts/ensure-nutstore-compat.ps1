<#
╔═══════════════════════════════════════════════════════════════╗
║  Nutstore / OpenClaw 兼容性维护脚本 (v2)
║
║  功能:
║    1. 确保 .openclaw/workspace 排除在坚果云同步之外
║    2. 移除已存在的 ReparsePoint 占位符
║    3. 将关键文件类型加入 Nutstore 锁忽略列表
║  触发: 开机自启 / 按需运行
╚═══════════════════════════════════════════════════════════════╝
#>

$OPENCLAW_DIR = "$env:USERPROFILE\.openclaw"
$WORKSPACE_DIR = Join-Path $OPENCLAW_DIR "workspace"
$NUTIGNORE = Join-Path $OPENCLAW_DIR ".nutignore"
$LOG_FILE = Join-Path $PSScriptRoot "nutstore-compat.log"
$BLACKLIST_FILE = "$env:APPDATA\Nutstore\config\AppLockedFilesBlackList.txt"

function Write-Log($msg) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$time | $msg"
    Write-Host $line
    $line | Out-File $LOG_FILE -Append -Encoding utf8
}

Write-Log "═══════ Nutstore 兼容性维护 v2 ═══════"

# 1. 确保 .nutignore 存在
if (Test-Path $NUTIGNORE) {
    $currentIgnore = Get-Content $NUTIGNORE -Raw -ErrorAction SilentlyContinue
    if ($currentIgnore -notmatch '^\*') {
        Write-Log "⚠️ .nutignore 内容不全，正在修复"
        Set-Content $NUTIGNORE -Value "*" -Encoding UTF8 -NoNewline
    } else {
        Write-Log "✅ .nutignore 已存在且有效"
    }
} else {
    Set-Content $NUTIGNORE -Value "*" -Encoding UTF8 -NoNewline
    Write-Log "✅ 已创建 .nutignore（忽略整个 .openclaw 目录）"
}

# 2. 扫描并移除 Workspace 的 ReparsePoint
Write-Log "正在扫描 workspace 中的 ReparsePoint 文件..."
$rpFiles = Get-ChildItem $WORKSPACE_DIR -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }
$count = $rpFiles.Count
if ($count -gt 0) {
    Write-Log "⚠️ 发现 $count 个文件有 ReparsePoint 属性"

    $svcDriver = Get-Service -Name NutstoreDriverSvc -ErrorAction SilentlyContinue
    if ($svcDriver.Status -eq 'Running') {
        Write-Log "正在暂停 Nutstore 驱动..."
        Stop-Service -Name NutstoreDriverSvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }

    $removed = 0
    foreach ($f in $rpFiles) {
        try {
            $current = $f.Attributes
            $clean = $current -band -bnot (1024 + 524288)
            if ($clean -ne $current) {
                Set-ItemProperty -Path $f.FullName -Name Attributes -Value $clean -ErrorAction SilentlyContinue
                $removed++
            }
        } catch {
            # 跳过无法修改的文件
        }
    }
    Write-Log "✅ 已移除 $removed/$count 个文件的 ReparsePoint"
} else {
    Write-Log "✅ workspace 中没有 ReparsePoint 文件"
}

# 3. 将关键文件类型加入 Nutstore 锁忽略列表
$extensionsToLock = @("jsonl", "json", "lock", "pid", "ldb", "log")
if (Test-Path $BLACKLIST_FILE) {
    $blacklist = Get-Content $BLACKLIST_FILE
    $blacklistChanged = $false
    foreach ($ext in $extensionsToLock) {
        $found = $false
        foreach ($line in $blacklist) {
            if ($line.Trim() -eq $ext) { $found = $true; break }
        }
        if (-not $found) {
            Add-Content $BLACKLIST_FILE -Value $ext
            Write-Log "✅ 已添加 .$ext 到 Nutstore 锁忽略列表"
            $blacklistChanged = $true
        }
    }
} else {
    Write-Log "ℹ️ AppLockedFilesBlackList.txt 不存在，跳过"
}

# 4. 重启 Nutstore 服务
$svcDriver = Get-Service -Name NutstoreDriverSvc -ErrorAction SilentlyContinue
$svcWatcher = Get-Service -Name NutstoreUSN -ErrorAction SilentlyContinue

if ($svcDriver.Status -eq 'Stopped') {
    Write-Log "正在重启 Nutstore 驱动..."
    Start-Service -Name NutstoreDriverSvc -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

if ($svcWatcher.Status -eq 'Stopped') {
    Start-Service -Name NutstoreUSN -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

Write-Log "✅ Nutstore 状态: Driver=$($svcDriver.Status), Watcher=$($svcWatcher.Status)"

# 5. 快速检测文件锁
$sessionDir = Join-Path $OPENCLAW_DIR "agents\main\sessions"
$sessions = Get-ChildItem $sessionDir -Filter "*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if ($sessions.Count -gt 0) {
    $latest = $sessions[0]
    try {
        $fs = [System.IO.File]::Open($latest.FullName, 'Open', 'ReadWrite', 'Read')
        $fs.Close()
        Write-Log "✅ Session 文件访问正常 ($($latest.Name))"
    } catch {
        Write-Log "❌ 仍然冲突: $($latest.Name) - $($_.Exception.Message)"
        Write-Log "   💡 建议: 重启 Nutstore 客户端或重启系统"
    }
}

Write-Log "═══════ 兼容性检查完成 ═══════"
