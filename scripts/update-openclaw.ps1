# OpenClaw Auto Update Script (Windows PowerShell)
# Usage:
#   .\scripts\update-openclaw.ps1          # check only
#   .\scripts\update-openclaw.ps1 update   # check + upgrade
#
# Schedule (daily 3am):
#   schtasks /create /tn OpenClawUpdate /tr "powershell -File scripts\update-openclaw.ps1 auto" /sc daily /st 03:00

param([string]$Action = "check")

$WORKSPACE = Split-Path -Parent $PSScriptRoot
$LOG = Join-Path $WORKSPACE "scripts\update-log.txt"
$NOW = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Get current version
$cur = "?"
try {
    $v = openclaw --version 2>&1 | Out-String
    if ($v -match 'OpenClaw (\d+\.\d+\.\d+)') { $cur = $Matches[1] }
} catch { $cur = "N/A" }

# Get latest from GitHub
$latest = "?"
$url = ""
try {
    $json = Invoke-RestMethod -Uri "https://api.github.com/repos/openclaw/openclaw/releases/latest" -TimeoutSec 10 -ErrorAction Stop
    if ($json.tag_name -match '(\d+\.\d+\.\d+)') { $latest = $Matches[1]; $url = $json.html_url }
} catch { $latest = "ERR" }

Write-Host "`n==========================="
Write-Host " OpenClaw Version Check"
Write-Host " Current: v$cur"
Write-Host " Latest:  v$latest"
Write-Host "==========================="

if ($latest -eq "ERR") { Write-Host "`n Cannot check latest version (no network)"; exit 1 }

# Compare versions
$needUpdate = $false
if ($cur -ne "?" -and $latest -ne "?") {
    $c = $cur -split '\.' | ForEach-Object { [int]$_ }
    $l = $latest -split '\.' | ForEach-Object { [int]$_ }
    for ($i = 0; $i -lt 3; $i++) { if ($l[$i] -gt $c[$i]) { $needUpdate = $true; break } }
}

if (-not $needUpdate) {
    Write-Host "`n [OK] Already latest version" -ForegroundColor Green
    "$NOW | OK: v$cur" | Out-File $LOG -Append -Encoding UTF8
    exit 0
}

Write-Host "`n [!!] New version v$latest available!" -ForegroundColor Yellow
Write-Host " $url"

if ($Action -eq "check") {
    Write-Host "`n Run: .\scripts\update-openclaw.ps1 update"
    exit 0
}

if ($Action -eq "update" -or $Action -eq "auto") {
    Write-Host "`n Upgrading..."
    npm install -g openclaw@latest 2>&1
    $v2 = openclaw --version 2>&1 | Out-String
    if ($v2 -match 'OpenClaw (\d+\.\d+\.\d+)') { $newVer = $Matches[1] } else { $newVer = "?" }
    Write-Host " Done: v$newVer" -ForegroundColor Green
    "$NOW | Upgrade: v$cur -> v$newVer" | Out-File $LOG -Append -Encoding UTF8
    Write-Host " Restart: openclaw gateway restart"
}
