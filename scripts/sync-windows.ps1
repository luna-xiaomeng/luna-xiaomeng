<#
.SYNOPSIS
    Xiaomeng Memory Sync Daemon (Windows)
.DESCRIPTION
    - Polls every 10s for local changes -> auto push to Gitee
    - Pulls every 20s from Gitee
    - Debounced, conflict-safe
#>

param()

$workspace   = Join-Path $env:USERPROFILE ".openclaw\workspace"
$logFile     = Join-Path $workspace "scripts\sync-windows.log"
$pidFile     = Join-Path $workspace "scripts\sync-windows.pid"

function Write-Log {
    param([string]$Msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time | $Msg" | Out-File -FilePath $logFile -Append -Encoding utf8
    Write-Host "$time | $Msg"
}

# Prevent duplicate
if (Test-Path $pidFile) {
    $oldPid = (Get-Content $pidFile -Raw).Trim()
    if ($oldPid -and (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)) {
        Write-Log "[WARN] Already running (PID: $oldPid), exiting"
        exit 0
    }
}
$pid.ToString() | Out-File -FilePath $pidFile -Encoding utf8

# Compute workspace hash to detect file changes (simple polling method)
function Get-WorkspaceHash {
    $files = Get-ChildItem $workspace -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -notmatch '\\.git[\\/]' -and `
        $_.Extension -notin '.log','.pid'
    }
    if (-not $files) { return "" }
    $hashInput = $files | ForEach-Object { "$($_.FullName):$($_.LastWriteTimeUtc.Ticks):$($_.Length)" }
    $inputStr = $hashInput -join "`n"
    # Use MD5 hash of the concatenated string to detect changes
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputStr)
    $hashBytes = $md5.ComputeHash($bytes)
    $hash = [BitConverter]::ToString($hashBytes) -replace '-', ''
    return $hash
}

# Git sync: pull + push
$syncing = $false
function Invoke-GitSync {
    if ($syncing) { return }
    $script:syncing = $true

    try {
        Push-Location $workspace

        # Pull
        $pullOut = git pull --rebase --autostash 2>&1
        if ($LASTEXITCODE -ne 0) {
            git merge --abort 2>$null
            git pull --no-rebase --autostash 2>&1 | Out-Null
        } else {
            $pullStr = "$pullOut"
            if ($pullStr -notmatch "Already up to date") {
                Write-Log "[PULL] Remote updated, pulled"
            }
        }

        # Check changes -> Push
        $status = git status --porcelain 2>&1
        if ($status) {
            git add -A 2>&1 | Out-Null
            git commit -m "auto sync $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>&1 | Out-Null
            $pushOut = git push origin master 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "[PUSH] Success ($(@($status)).Count files)"
            } else {
                Write-Log "[ERR] Push failed: $pushOut"
            }
        }

        Pop-Location
    } catch {
        Write-Log "[ERR] Git error: $_"
    } finally {
        $script:syncing = $false
    }
}

# Main loop (polling)
Write-Log "[START] Xiaomeng sync daemon started"
Write-Log "[INFO] Dir: $workspace"
Write-Log "[INFO] Remote: $(git -C $workspace remote get-url origin 2>&1)"
Write-Log "[INFO] Poll interval: 10s"

$lastHash = Get-WorkspaceHash
$lastPullTime = Get-Date

while ($true) {
    $now = Get-Date

    # Pull every 20s
    if (($now - $lastPullTime).TotalSeconds -ge 20) {
        Invoke-GitSync
        $lastPullTime = $now
        $lastHash = Get-WorkspaceHash
    }

    # Check local changes every 10s
    $currentHash = Get-WorkspaceHash
    if ($currentHash -ne $lastHash) {
        Write-Log "[CHANGE] File changes detected"
        Start-Sleep -Seconds 3
        Invoke-GitSync
        $lastHash = Get-WorkspaceHash
        $lastPullTime = Get-Date
    }

    Start-Sleep -Seconds 10
}

Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
