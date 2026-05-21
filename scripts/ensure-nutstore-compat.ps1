<#
╔═══════════════════════════════════════════════════════════════╗
║  Nutstore / OpenClaw 兼容性维护脚本                          ║
║                                                              ║
║  功能: 确保 Nutstore 服务不会与 OpenClaw 产生文件锁冲突      ║
║  触发: 开机自启 / 按需运行                                   ║
╚═══════════════════════════════════════════════════════════════╝
#>

$OPENCLAW_DIR = "$env:USERPROFILE\.openclaw"
$NUTIGNORE = Join-Path $OPENCLAW_DIR ".nutignore"
$LOG_FILE = Join-Path $PSScriptRoot "nutstore-compat.log"

function Write-Log($msg) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$time | $msg"
    Write-Host $line
    $line | Out-File $LOG_FILE -Append -Encoding utf8
}

# 1. Check .nutignore exists
if (Test-Path $NUTIGNORE) {
    Write-Log "✅ .nutignore 已存在"
} else {
    $content = @"
# Nutstore ignore file - ignore OpenClaw data directory
# Prevents file lock conflicts (EBUSY)
*
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($NUTIGNORE, $content, $utf8NoBom)
    Write-Log "✅ 已创建 .nutignore"
}

# 2. Check Nutstore services status
$svcDriver = Get-Service -Name NutstoreDriverSvc -ErrorAction SilentlyContinue
$svcWatcher = Get-Service -Name NutstoreUSN -ErrorAction SilentlyContinue

if ($svcDriver.Status -eq 'Running' -and $svcWatcher.Status -eq 'Running') {
    Write-Log "✅ Nutstore 服务正常运行"
} elseif ($svcDriver.Status -eq 'Running' -or $svcWatcher.Status -eq 'Running') {
    Write-Log "⚠️ Nutstore 服务部分运行（Driver: $($svcDriver.Status), Watcher: $($svcWatcher.Status)）"
} else {
    Write-Log "ℹ️ Nutstore 服务已停止（不影响坚果云同步客户端）"
}

# 3. Quick EBUSY test on latest session file
$sessionDir = Join-Path $OPENCLAW_DIR "agents\main\sessions"
$sessions = Get-ChildItem $sessionDir -Filter "*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if ($sessions.Count -gt 0) {
    $latest = $sessions[0]
    try {
        $fs = [System.IO.File]::Open($latest.FullName, 'Open', 'ReadWrite', 'Read')
        $fs.Close()
        Write-Log "✅ Session 文件访问正常 ($($latest.Name))"
    } catch {
        Write-Log "❌ EBUSY 冲突! $($latest.Name): $($_.Exception.Message)"
        Write-Log "   ⏳ 尝试重启 Nutstore 服务..."
        
        # Restart services
        Restart-Service -Name NutstoreDriverSvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Restart-Service -Name NutstoreUSN -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        
        # Re-test
        try {
            $fs = [System.IO.File]::Open($latest.FullName, 'Open', 'ReadWrite', 'Read')
            $fs.Close()
            Write-Log "✅ 重启后恢复"
        } catch {
            Write-Log "❌ 仍然冲突，建议重启 Nutstore 客户端或系统"
        }
    }
}

Write-Log "✅ 兼容性检查完成"
