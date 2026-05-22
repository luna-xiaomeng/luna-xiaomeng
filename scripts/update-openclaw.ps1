# OpenClaw Auto Update Script v2.1 (Windows PowerShell)
# Fixes: 升级后依赖缺失 -> 自动npm install补全 -> 修复服务定义 -> 重启网关
# Usage:
#   .\scripts\update-openclaw.ps1          # check only
#   .\scripts\update-openclaw.ps1 update   # check + full upgrade
#
# Schedule (daily 3am):
#   schtasks /create /tn OpenClawUpdate /tr "powershell -File C:\full\path\to\scripts\update-openclaw.ps1 auto" /sc daily /st 03:00

param([string]$Action = "check")

$WORKSPACE = Split-Path -Parent $PSScriptRoot
$LOG = Join-Path $WORKSPACE "scripts\update-log.txt"
$NOW = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$OPENCLAW_DIR = (Get-Command openclaw).Source -replace 'openclaw\.cmd$|openclaw$', '' -replace '\\$', ''

# ====== Helper: get version ======
function Get-OpenClawVersion {
    try {
        $v = openclaw --version 2>&1 | Out-String
        if ($v -match 'OpenClaw (\d+\.\d+\.\d+)') { return $Matches[1] }
    } catch {}
    return "N/A"
}

# ====== Helper: install dependencies ======
function Install-Dependencies {
    Write-Host "  Installing bundled dependencies..."
    Push-Location $OPENCLAW_DIR
    $result = npm install 2>&1 | Out-String
    Pop-Location
    
    # Check for specific dependency errors
    $missing = $result -match "Cannot find module"
    if ($missing) {
        Write-Host "  Some deps still missing, trying direct install..." -ForegroundColor Yellow
        Push-Location $OPENCLAW_DIR
        npm install @earendil-works/pi-coding-agent @earendil-works/pi-agent-core @earendil-works/pi-ai @earendil-works/pi-tui 2>&1 | Out-Null
        Pop-Location
    }
}

# ====== Helper: repair and restart gateway ======
function Repair-And-Restart {
    Write-Host "  Repairing gateway service definition..."
    $result = openclaw gateway start 2>&1 | Out-String
    if ($result -match "repaired|started|running") {
        Write-Host "  Gateway restarted successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  Gateway start output:" -ForegroundColor Gray
        $result -split "`n" | ForEach-Object { Write-Host "    $_" }
        Write-Host "  Trying alternative: openclaw gateway restart..." -ForegroundColor Yellow
        $r2 = openclaw gateway restart 2>&1 | Out-String
        if ($r2 -match "repaired|started|running|ok") {
            Write-Host "  Gateway restarted successfully" -ForegroundColor Green
            return $true
        }
        return $false
    }
}

# ====== Main ======
$cur = Get-OpenClawVersion

# Get latest from GitHub
$latest = "?"
$url = ""
try {
    $json = Invoke-RestMethod -Uri "https://api.github.com/repos/openclaw/openclaw/releases/latest" -TimeoutSec 10 -ErrorAction Stop
    if ($json.tag_name -match '(\d+\.\d+\.\d+)') { $latest = $Matches[1]; $url = $json.html_url }
} catch { $latest = "ERR" }

Write-Host "`n==========================="
Write-Host " OpenClaw Auto Update v2.1"
Write-Host " Current: v$cur"
Write-Host " Latest:  v$latest"
Write-Host "==========================="

if ($latest -eq "ERR") { Write-Host "`n Cannot check latest (no network)"; exit 1 }

# Compare
$needUpdate = $false
if ($cur -ne "N/A" -and $latest -ne "?") {
    $c = $cur -split '\.' | ForEach-Object { [int]$_ }
    $l = $latest -split '\.' | ForEach-Object { [int]$_ }
    for ($i = 0; $i -lt 3; $i++) { if ($l[$i] -gt $c[$i]) { $needUpdate = $true; break } }
}

if (-not $needUpdate) {
    Write-Host "`n [OK] v$cur is latest" -ForegroundColor Green
    "$NOW | OK: v$cur" | Out-File $LOG -Append -Encoding UTF8
    exit 0
}

Write-Host "`n [!!] New version v$latest!" -ForegroundColor Yellow

if ($Action -eq "check") {
    Write-Host " Run: .\scripts\update-openclaw.ps1 update"
    exit 0
}

if ($Action -eq "update" -or $Action -eq "auto") {
    Write-Host "`n === Step 1: npm global upgrade ==="
    npm install -g openclaw@latest 2>&1 | Out-String
    
    $newVer = Get-OpenClawVersion
    Write-Host " CLI version: v$newVer"
    
    Write-Host "`n === Step 2: Install bundled deps ==="
    Install-Dependencies
    
    Write-Host "`n === Step 3: Repair + restart gateway ==="
    $ok = Repair-And-Restart
    
    if ($ok) {
        Write-Host "`n [OK] Upgrade complete: v$cur -> v$newVer" -ForegroundColor Green
        "$NOW | OK: v$cur -> v$newVer" | Out-File $LOG -Append -Encoding UTF8
    } else {
        Write-Host "`n [!!] Upgrade done but gateway restart may need manual: openclaw gateway start" -ForegroundColor Yellow
        "$NOW | PARTIAL: v$cur -> v$newVer (gateway manual restart)" | Out-File $LOG -Append -Encoding UTF8
    }
}
