param()

$nutstoreRoot = "C:\Users\Administrator\Nutstore\1"
$backupDir = Join-Path $nutstoreRoot "小梦记忆"
$workspace = "C:\Users\Administrator\.openclaw\workspace"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$logFile = Join-Path $backupDir "backup_log.txt"

if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$historyDir = Join-Path $backupDir "history"
if (-not (Test-Path $historyDir)) { New-Item -ItemType Directory -Path $historyDir -Force | Out-Null }

$logLines = @()
$logLines += "========== 小梦记忆双向同步 - $timestamp =========="

$sshKey = "$env:USERPROFILE\.ssh\id_ed25519"
$server = "root@139.196.51.45"
$remotePath = "/root/xiaomeng-backup"
$sshOpts = "-i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=10"

$coreFiles = @(
    "MEMORY.md", "IDENTITY.md", "SOUL.md",
    "AGENTS.md", "TOOLS.md", "USER.md", "HEARTBEAT.md"
)

$dirsToSync = @("memory", "avatars")
$historyLimit = 30

# ==============================================================
# 辅助函数：从服务器获取文件 mtime（Unix 时间戳）
# ==============================================================
function Get-ServerMtime($fileName) {
    $escaped = $fileName -replace "'", "'\\''"
    $cmd = "stat -c '%Y' '$remotePath/$escaped' 2>/dev/null || echo 0"
    $result = & ssh -i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=5 $server $cmd 2>$null
    if ($LASTEXITCODE -eq 0 -and $result -match '^\d+$') {
        return [long]$result
    }
    return 0
}

# ==============================================================
# 辅助函数：同步单个文件（根据时间戳）
# 方向：$direction = "pull"（服务器→本地）或 "push"（本地→服务器）
# ==============================================================
function Sync-File($fileName, $direction) {
    $localFile = Join-Path $workspace $fileName
    $backupFile = Join-Path $backupDir $fileName
    
    if ($direction -eq "pull") {
        # 服务器→本地
        $serverMtime = Get-ServerMtime $fileName
        if ($serverMtime -eq 0) { return $false }  # 服务器上没有
        
        $localTime = 0
        if (Test-Path $localFile) {
            $localTime = [long]((Get-Item $localFile).LastWriteTime.ToUniversalTime() - (Get-Date "1970-01-01").ToUniversalTime()).TotalSeconds
        }
        
        if ($serverMtime -gt $localTime) {
            # 服务器文件更新 → 下载
            $escaped = $fileName -replace "'", "'\\''"
            & scp -i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${server}:${remotePath}/${escaped}" "$backupFile" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Copy-Item $backupFile $localFile -Force
                return $true  # pulled
            }
        }
    } else {
        # 本地→服务器
        if (-not (Test-Path $localFile)) { return $false }
        $localTime = [long]((Get-Item $localFile).LastWriteTime.ToUniversalTime() - (Get-Date "1970-01-01").ToUniversalTime()).TotalSeconds
        $localTime = [math]::Round($localTime)
        
        $serverMtime = Get-ServerMtime $fileName
        if ($localTime -gt $serverMtime) {
            # 本地文件更新 → 上传
            $escaped = $fileName -replace "'", "'\\''"
            & scp -i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=10 $localFile "${server}:${remotePath}/${escaped}" 2>$null
            if ($LASTEXITCODE -eq 0) {
                return $true  # pushed
            }
        }
    }
    return $false
}

# ==============================================================
# 第一阶段：从服务器拉取（微信小梦的变更 → 本地）
# ==============================================================
$logLines += "--- [Phase 1] Pull: server → local ---"
$pullCount = 0
foreach ($file in $coreFiles) {
    if (Sync-File $file "pull") {
        $logLines += "  ↓ $file (newer on server)"
        $pullCount++
    }
}

# 同步子目录（data/shared/memory/, assets/avatars/）
foreach ($dir in $dirsToSync) {
    # SSH 列出服务器上该目录的所有文件
    $escapedDir = $dir -replace "'", "'\\''"
    $listCmd = "find '$remotePath/$escapedDir' -maxdepth 1 -type f -printf '%f\n' 2>/dev/null"
    $remoteFiles = & ssh -i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=5 $server $listCmd 2>$null
    if ($LASTEXITCODE -eq 0 -and $remoteFiles) {
        $remoteFiles = $remoteFiles -split "`n" | Where-Object { $_ -ne '' }
        foreach ($rf in $remoteFiles) {
            $subFile = "$dir/$rf"
            if (Sync-File $subFile "pull") {
                $logLines += "  ↓ $subFile (newer on server)"
                $pullCount++
            }
        }
    }
}

# 更新本地坚果云备份目录（从 workspace 拉取的已是最新）
if ($pullCount -gt 0) {
    $logLines += "  [OK] Pulled $pullCount newer files from server"
} else {
    $logLines += "  [OK] Local files are already up to date"
}

# ==============================================================
# 第二阶段：本地 → 坚果云备份
# ==============================================================
$logLines += "--- [Phase 2] Local → Nutstore ---"
$localCount = 0
foreach ($file in $coreFiles) {
    $src = Join-Path $workspace $file
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $backupDir $file) -Force
        $localCount++
        # 归档历史版本
        $safeName = $file -replace '\.', '_'
        Copy-Item $src (Join-Path $historyDir "${safeName}_$timestamp.txt") -Force
    }
}
$logLines += "  [OK] $localCount core files → Nutstore"

# memory/
$memoryWs = Join-Path $workspace "data/shared/memory"
if (Test-Path $memoryWs) {
    $memoryBk = Join-Path $backupDir "memory"
    if (-not (Test-Path $memoryBk)) { New-Item -ItemType Directory -Path $memoryBk -Force | Out-Null }
    Get-ChildItem $memoryWs -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $memoryBk $_.Name) -Force
    }
    $logLines += "  [OK] data/shared/memory/ ($((Get-ChildItem $memoryWs -File).Count) files)"
}

# avatars/
$avatarWs = Join-Path $workspace "assets/avatars"
if (Test-Path $avatarWs) {
    $avatarBk = Join-Path $backupDir "avatars"
    if (-not (Test-Path $avatarBk)) { New-Item -ItemType Directory -Path $avatarBk -Force | Out-Null }
    Get-ChildItem $avatarWs -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $avatarBk $_.Name) -Force
    }
    $logLines += "  [OK] assets/avatars/"
}

# 清理旧历史版本
$historyFiles = Get-ChildItem $historyDir -File | Sort-Object LastWriteTime -Descending
if ($historyFiles.Count -gt $historyLimit) {
    $toDelete = $historyFiles | Select-Object -Skip $historyLimit
    foreach ($f in $toDelete) { Remove-Item $f.FullName -Force }
    $logLines += "  [CLEAN] removed $($toDelete.Count) old history versions"
}

# ==============================================================
# 第三阶段：推送至阿里云（本地新版本 → 服务器）
# ==============================================================
$logLines += "--- [Phase 3] Push: local → server ---"
$pushCount = 0
foreach ($file in $coreFiles) {
    if (Sync-File $file "push") {
        $logLines += "  ↑ $file (newer locally)"
        $pushCount++
    }
}

foreach ($dir in $dirsToSync) {
    $localDir = Join-Path $workspace $dir
    if (Test-Path $localDir) {
        Get-ChildItem $localDir -File | ForEach-Object {
            $subFile = "$dir/$($_.Name)"
            if (Sync-File $subFile "push") {
                $logLines += "  ↑ $subFile (newer locally)"
                $pushCount++
            }
        }
    }
}

if ($pushCount -gt 0) {
    $logLines += "  [OK] Pushed $pushCount newer files to server"
} else {
    $logLines += "  [OK] Server files are already up to date"
}

# ==============================================================
# 第四阶段：触发服务器端同步到 admin workspace（微信小梦）
# ==============================================================
$logLines += "--- [Phase 4] Trigger admin workspace sync ---"
try {
    $triggerCmd = @"
# 将备份目录的最新状态同步到 admin workspace
rsync -a --include='*.md' --include='data/' --include='assets/' --exclude='*' $remotePath/ /root/.openclaw/workspace/ 2>/dev/null
chown -R root:root /root/.openclaw/workspace/*.md /root/.openclaw/workspace/data /root/.openclaw/workspace/assets 2>/dev/null
echo "ADMIN_SYNC_OK"
"@
    $adminResult = & ssh -i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=10 $server $triggerCmd 2>&1
    if ($adminResult -match "ADMIN_SYNC_OK") {
        $logLines += "  [OK] Admin workspace synced (微信小梦已更新)"
    } else {
        $logLines += "  [OK] Rsync on server will catch it in 5 min"
    }
} catch {
    $logLines += "  [WARN] Admin sync trigger: $_"
}

# ==============================================================
# 总结
# ==============================================================
$total = $pullCount + $pushCount + $localCount
$logLines += "`n--- Summary: pulled $pullCount ↑ pushed $pushCount ↑ local $localCount ---"
$logLines += "Time: $timestamp"
$logLines | Out-File -FilePath $logFile -Encoding UTF8 -Append

Set-Content -Path (Join-Path $backupDir "status.txt") -Value "xiaomeng-memory-status - last: $timestamp" -Encoding UTF8

Write-Output "✅ 双向同步完成 at $timestamp (pulled $pullCount, pushed $pushCount)"
