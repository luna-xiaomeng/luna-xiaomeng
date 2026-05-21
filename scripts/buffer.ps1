<#
╔═══════════════════════════════════════════════════════════════╗
║   XiaoMeng Buffer Tool (Windows / PowerShell)              ║
║   本地小梦 <-> 云端小梦 workspace exchange via Gitee       ║
╚═══════════════════════════════════════════════════════════════╝
Usage:
  scripts/buffer.ps1 submit <file> [--reason "reason"] [--target dest]
  scripts/buffer.ps1 list [--all]
  scripts/buffer.ps1 show <id>
  scripts/buffer.ps1 review <id> approve|reject [--note "note"]
  scripts/buffer.ps1 merge <id>
  scripts/buffer.ps1 reject <id> [--note "reason"]
  scripts/buffer.ps1 message <text>
  scripts/buffer.ps1 status
  scripts/buffer.ps1 history
#>

param(
    [string]$Action = "status",
    [string]$File = "",
    [string]$Id = "",
    [string]$Reason = "",
    [string]$Target = "",
    [string]$Note = "",
    [string]$Message = "",
    [switch]$All = $false,
    [string]$Decision = ""
)

# --- Configuration ---
$WORKSPACE = Split-Path -Parent $PSScriptRoot
$BUFFER = Join-Path $WORKSPACE "buffer"
$MANIFEST = Join-Path $BUFFER "_manifest.json"
$MESSAGES_DIR = Join-Path $BUFFER "_messages"
$PENDING = Join-Path $BUFFER "pending"
$APPROVED = Join-Path $BUFFER "approved"
$MERGED = Join-Path $BUFFER "merged"
$REJECTED = Join-Path $BUFFER "rejected"
$COUNTER_FILE = Join-Path $BUFFER ".counter"

# Colors
$C_RED = "Red"
$C_GREEN = "Green"
$C_YELLOW = "Yellow"
$C_MAGENTA = "Magenta"
$C_CYAN = "Cyan"
$C_WHITE = "White"
$C_GRAY = "Gray"
$C_DKGRAY = "DarkGray"

# --- Helpers ---
function Write-BomFile($path, $content) {
    $utf8 = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
}

function Get-NextId {
    $today = Get-Date -Format "yyyyMMdd"
    $counter = 1
    if (Test-Path $COUNTER_FILE) {
        $last = Get-Content $COUNTER_FILE -Raw -ErrorAction SilentlyContinue
        if ($last -match "$today-(\d+)") {
            $counter = [int]$Matches[1] + 1
        }
    }
    $id = "buf-$today-$( '{0:D3}' -f $counter )"
    $id | Set-Content $COUNTER_FILE -NoNewline -Encoding ASCII
    return $id
}

function Get-Manifest {
    if (Test-Path $MANIFEST) {
        try {
            $json = Get-Content $MANIFEST -Raw -Encoding UTF8 -ErrorAction Stop
            return ($json | ConvertFrom-Json -ErrorAction Stop)
        } catch {
            return @{ entries = @() }
        }
    }
    return @{ entries = @() }
}

function Save-Manifest($manifest) {
    $manifest.entries = @($manifest.entries | Sort-Object -Property created -Descending)
    $json = $manifest | ConvertTo-Json -Depth 3
    Write-BomFile $MANIFEST $json
}

function Get-FrontMatter($path) {
    $content = Get-Content $path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return @{} }
    if ($content -match '(?s)^---\s*\n(.+?)\n---') {
        $fm = $Matches[1]
        $data = @{}
        foreach ($line in $fm -split '\r?\n') {
            if ($line -match '^(\w+):\s*"?([^"]*)"?') {
                $data[$Matches[1]] = $Matches[2].Trim()
            }
        }
        return $data
    }
    return @{}
}

function Get-Body($path) {
    $content = Get-Content $path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return "" }
    return $content -replace '(?s)^---\s*\n.*?\n---\s*\n', ''
}

function Update-FileStatus($path, $newStatus, $reviewer, $reviewNote, $extraField, $extraValue) {
    $content = [System.IO.File]::ReadAllText($path)
    if (-not $content) { return }
    # Split front matter and body
    if ($content -match '(?s)^---\s*\n(.+?)\n---') {
        $fmBlock = $Matches[1]
        $bodyStart = $Matches[0].Length
        $body = $content.Substring($bodyStart)
        $fmLines = $fmBlock -split '\r?\n'
        $keep = @{}
        foreach ($line in $fmLines) {
            if ($line -match '^(\w+):(.*)$') {
                $keep[$Matches[1]] = $Matches[2].Trim()
            }
        }
        # Update fields
        $keep['status'] = $newStatus
        if ($reviewer) { $keep['reviewer'] = $reviewer }
        if ($reviewNote) { $keep['review_note'] = $reviewNote }
        if ($extraField -and $extraValue) { $keep[$extraField] = $extraValue }
        # Rebuild front matter
        $newFmLines = @()
        foreach ($key in $keep.Keys) {
            $newFmLines += ("${key}: " + $keep[$key])
        }
        $newContent = "---`n" + ($newFmLines -join "`n") + "`n---" + $body
        [System.IO.File]::WriteAllText($path, $newContent, [System.Text.UTF8Encoding]::new($true))
    }
}

function Update-Manifest($id, $status, $file, $extra) {
    $manifest = Get-Manifest
    foreach ($entry in $manifest.entries) {
        if ($entry.id -eq $id) {
            $entry.status = $status
            $entry.file = $file
        }
    }
    Save-Manifest $manifest
}

function Find-ById($id, $dirs) {
    foreach ($dir in $dirs) {
        $full = Join-Path $BUFFER $dir
        if (-not (Test-Path $full)) { continue }
        $pattern = Join-Path $full "*.md"
        $files = Get-ChildItem $pattern -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            if ($f.BaseName -like "$id*") {
                return @{ Path = $f.FullName; Dir = $dir; Name = $f.Name }
            }
        }
    }
    return $null
}

function Show-Entry($dir, $file) {
    $path = Join-Path (Join-Path $BUFFER $dir) $file
    if (-not (Test-Path $path)) { return }
    $data = Get-FrontMatter $path
    $line = "  [$($data.id)] $($data.source)"
    Write-Host $line -ForegroundColor White
    $line2 = "         from: $($data.submitter) | $($data.created)"
    Write-Host $line2 -ForegroundColor Gray
    if ($data.reason) {
        Write-Host "         reason: $($data.reason)" -ForegroundColor Gray
    }
    Write-Host ""
}

# --- Actions ---
function Action-Submit {
    if (-not $File) {
        Write-Host "ERROR: Please specify a file to submit" -ForegroundColor $C_RED
        return
    }
    $srcPath = Resolve-Path $File -ErrorAction SilentlyContinue
    if (-not $srcPath) {
        Write-Host "ERROR: File not found: $File" -ForegroundColor $C_RED
        return
    }
    $content = Get-Content $srcPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Host "ERROR: Cannot read file: $File" -ForegroundColor $C_RED
        return
    }
    $relPath = $srcPath.Path
    if ($relPath -match [regex]::Escape($WORKSPACE)) {
        $relPath = $relPath.Substring($WORKSPACE.Length + 1)
    }

    $id = Get-NextId
    $today = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $targetPath = $(if ($Target) { $Target } else { $relPath })
    $reasonText = $(if ($Reason) { $Reason } else { "" })
    $leaf = Split-Path $relPath -Leaf
    $outName = "$id-$leaf"
    $outPath = Join-Path $PENDING $outName

    $header = @"
---
id: $id
submitter: 本地小梦
source: $relPath
target: $targetPath
created: $today
status: pending
priority: normal
reason: $reasonText
---

"@
    Write-BomFile $outPath ($header + $content)

    $manifest = Get-Manifest
    $manifest.entries += @{
        id = $id; submitter = "本地小梦"; source = $relPath
        target = $targetPath; created = $today
        status = "pending"; priority = "normal"
        reason = $Reason; file = "pending/$outName"
    }
    Save-Manifest $manifest

    Write-Host "[OK] Submitted to buffer [$id]" -ForegroundColor $C_GREEN
    Write-Host "    Source: $relPath" -ForegroundColor $C_CYAN
    Write-Host "    File: buffer/pending/$outName" -ForegroundColor $C_CYAN
    Write-Host "    Reason: $(if ($Reason) { $Reason } else { '(none)' })" -ForegroundColor $C_YELLOW
    Write-Host "`nWaiting for Cloud Xiaomeng to review..." -ForegroundColor $C_GRAY
}

function Action-List {
    Write-Host "`nBuffer Manifest" -ForegroundColor $C_MAGENTA
    Write-Host ("=" * 40) -ForegroundColor $C_DKGRAY

    $dirConfigs = @(
        @{ Name = "pending"; Label = "PENDING"; Color = $C_YELLOW },
        @{ Name = "approved"; Label = "APPROVED"; Color = $C_GREEN },
        @{ Name = "merged"; Label = "MERGED"; Color = $C_DKGRAY },
        @{ Name = "rejected"; Label = "REJECTED"; Color = $C_RED }
    )

    foreach ($dc in $dirConfigs) {
        if ((-not $All) -and ($dc.Name -ne "pending")) { continue }
        $p = Join-Path (Join-Path $BUFFER $dc.Name) "*.md"
        $entries = @(Get-ChildItem $p -ErrorAction SilentlyContinue)
        if ($entries.Count -eq 0) { continue }
        Write-Host "`n[$($dc.Label)] ($($entries.Count))" -ForegroundColor $dc.Color
        Write-Host ("-" * 30) -ForegroundColor $C_DKGRAY
        foreach ($entry in $entries) {
            Show-Entry $dc.Name $entry.Name
        }
    }

    if ($All) {
        $msgPattern = Join-Path $MESSAGES_DIR "*.md"
        $msgs = @(Get-ChildItem $msgPattern -ErrorAction SilentlyContinue)
        if ($msgs.Count -gt 0) {
            Write-Host "`n[MESSAGES] ($($msgs.Count))" -ForegroundColor $C_CYAN
            Write-Host ("-" * 30) -ForegroundColor $C_DKGRAY
            foreach ($m in $msgs) {
                $content = Get-Content $m.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                $preview = ""
                if ($content) {
                    $lines = $content -split "`n"
                    foreach ($ln in $lines) {
                        if ($ln -match '^\*\*[^*]+\*\*') {
                            $preview = $ln -replace '^\*\*', '' -replace '\*\*$', ''
                            break
                        }
                    }
                }
                Write-Host "  [$($m.BaseName)] $preview" -ForegroundColor White
            }
        }
    }

    if (-not $All) {
        Write-Host "`nTip: use --all to see all statuses" -ForegroundColor $C_DKGRAY
    }
}

function Action-Show {
    if (-not $Id) {
        Write-Host "ERROR: Usage: buffer show <id>" -ForegroundColor $C_RED
        return
    }
    $result = Find-ById $Id @("pending", "approved", "merged", "rejected")
    if (-not $result) {
        Write-Host "ERROR: ID not found: $Id" -ForegroundColor $C_RED
        return
    }
    $content = Get-Content $result.Path -Raw -Encoding UTF8
    Write-Host "`n[File] $($result.Name)" -ForegroundColor $C_MAGENTA
    Write-Host ("=" * 40) -ForegroundColor $C_DKGRAY
    Write-Host ""
    Write-Host $content -ForegroundColor $C_WHITE
}

function Action-Review {
    if (-not $Id -or -not $Decision) {
        Write-Host "ERROR: Usage: buffer review <id> approve|reject [--note ""note""]" -ForegroundColor $C_RED
        return
    }
    if ($Decision -notin @("approve", "reject")) {
        Write-Host "ERROR: Decision must be approve or reject" -ForegroundColor $C_RED
        return
    }
    $result = Find-ById $Id @("pending")
    if (-not $result) {
        Write-Host "ERROR: ID not found in pending: $Id" -ForegroundColor $C_RED
        return
    }
    $newStatus = $(if ($Decision -eq "approve") { "approved" } else { "rejected" })
    $targetDir = Join-Path $BUFFER $(if ($Decision -eq "approve") { "approved" } else { "rejected" })
    $targetPath = Join-Path $targetDir $result.Name
    # Copy first, then update status in new location, then remove original
    Copy-Item $result.Path $targetPath -Force
    Start-Sleep -Milliseconds 100
    Update-FileStatus $targetPath $newStatus "本地小梦" $Note $null $null
    Remove-Item $result.Path -Force -ErrorAction SilentlyContinue
    Update-Manifest $Id $newStatus "$(Split-Path $targetDir -Leaf)/$($result.Name)" @{}

    $emoji = $(if ($Decision -eq "approve") { "[OK]" } else { "[REJ]" })
    Write-Host "$emoji $($(if ($Decision -eq "approve") { "Approved" } else { "Rejected" })) [$Id]" -ForegroundColor $C_GREEN
    if ($Note) { Write-Host "    Note: $Note" -ForegroundColor $C_YELLOW }
    Write-Host "    File moved to buffer/$newStatus/" -ForegroundColor $C_CYAN
}

function Action-Merge {
    if (-not $Id) {
        Write-Host "ERROR: Usage: buffer merge <id>" -ForegroundColor $C_RED
        return
    }
    $result = Find-ById $Id @("approved")
    if (-not $result) {
        Write-Host "ERROR: ID not found in approved: $Id" -ForegroundColor $C_RED
        return
    }
    $data = Get-FrontMatter $result.Path
    $targetPath = $(if ($data.target) { $data.target } else { $data.source })
    if (-not $targetPath) {
        Write-Host "ERROR: Cannot resolve target path" -ForegroundColor $C_RED
        return
    }
    $absTarget = $(if ([System.IO.Path]::IsPathRooted($targetPath)) { $targetPath } else { Join-Path $WORKSPACE $targetPath })
    $body = Get-Body $result.Path
    if (-not $body) {
        Write-Host "ERROR: File body is empty" -ForegroundColor $C_RED
        return
    }
    if (Test-Path $absTarget) {
        Copy-Item $absTarget "$absTarget.bak" -Force
        Write-Host "[BAK] Backed up to $absTarget.bak" -ForegroundColor $C_DKGRAY
    }
    Write-BomFile $absTarget $body
    Write-Host "[WRT] Written: $absTarget" -ForegroundColor $C_GREEN

    $mergedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Update-FileStatus $result.Path "merged" $null $null "merged_at" $mergedAt
    Copy-Item $result.Path (Join-Path $MERGED $result.Name) -Force
    Remove-Item $result.Path
    Update-Manifest $Id "merged" "merged/$($result.Name)" @{ merged_at = $mergedAt }

    Write-Host "[DONE] [$Id] merged and archived" -ForegroundColor $C_GREEN
}

function Action-Reject {
    if (-not $Id) {
        Write-Host "ERROR: Usage: buffer reject <id> [--note ""reason""]" -ForegroundColor $C_RED
        return
    }
    $result = Find-ById $Id @("pending", "approved")
    if (-not $result) {
        Write-Host "ERROR: ID not found: $Id" -ForegroundColor $C_RED
        return
    }
    Update-FileStatus $result.Path "rejected" "本地小梦" $Note $null $null
    Copy-Item $result.Path (Join-Path $REJECTED $result.Name) -Force
    Remove-Item $result.Path
    Update-Manifest $Id "rejected" "rejected/$($result.Name)" @{}

    Write-Host "[REJ] Rejected [$Id]" -ForegroundColor $C_RED
    if ($Note) { Write-Host "    Reason: $Note" -ForegroundColor $C_YELLOW }
    Write-Host "    File moved to buffer/rejected/" -ForegroundColor $C_DKGRAY
}

function Action-Message {
    if (-not $Message) {
        Write-Host "ERROR: Usage: buffer message <text>" -ForegroundColor $C_RED
        return
    }
    $nextNum = 1
    $mPattern = Join-Path $MESSAGES_DIR "*.md"
    $existing = @(Get-ChildItem $mPattern -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) {
        $max = ($existing | ForEach-Object {
            if ($_.BaseName -match '^(\d+)') { [int]$Matches[1] } else { 0 }
        } | Measure-Object -Maximum).Maximum
        $nextNum = $max + 1
    }
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $padded = $("{0:D4}" -f $nextNum) + "-from-local.md"
    $msgContent = @"
> **From: Local Xiaomeng [PC]**
> **Time: $stamp**
> 
> $Message
---
*Auto-synced via buffer*
"@
    $msgFile = Join-Path $MESSAGES_DIR $padded
    Write-BomFile $msgFile $msgContent
    Write-Host "[MSG] Message sent" -ForegroundColor $C_CYAN
    Write-Host "  $Message" -ForegroundColor $C_WHITE
    Write-Host "  Location: buffer/_messages/$padded" -ForegroundColor $C_DKGRAY
}

function Action-Status {
    $pendingCount  = @(Get-ChildItem (Join-Path $PENDING "*.md") -ErrorAction SilentlyContinue).Count
    $approvedCount = @(Get-ChildItem (Join-Path $APPROVED "*.md") -ErrorAction SilentlyContinue).Count
    $mergedCount   = @(Get-ChildItem (Join-Path $MERGED "*.md") -ErrorAction SilentlyContinue).Count
    $rejectedCount = @(Get-ChildItem (Join-Path $REJECTED "*.md") -ErrorAction SilentlyContinue).Count
    $m = Join-Path $MESSAGES_DIR "*.md"
    $msgCount      = @(Get-ChildItem $m -ErrorAction SilentlyContinue).Count

    Write-Host "`nBuffer Status" -ForegroundColor $C_MAGENTA
    Write-Host ("=" * 40) -ForegroundColor $C_DKGRAY
    Write-Host "  PENDING:   $pendingCount" -ForegroundColor $C_YELLOW
    Write-Host "  APPROVED:  $approvedCount" -ForegroundColor $C_GREEN
    Write-Host "  MERGED:    $mergedCount" -ForegroundColor $C_DKGRAY
    Write-Host "  REJECTED:  $rejectedCount" -ForegroundColor $C_RED
    Write-Host "  MESSAGES:  $msgCount" -ForegroundColor $C_CYAN
    Write-Host ("-" * 30) -ForegroundColor $C_DKGRAY
    Write-Host "  Self: Local Xiaomeng (Windows)" -ForegroundColor $C_WHITE
    Write-Host "  Peer: Cloud Xiaomeng (Aliyun)" -ForegroundColor $C_WHITE
    Write-Host ("=" * 40) -ForegroundColor $C_DKGRAY

    if ($pendingCount -gt 0) {
        Write-Host "`nPending Items:" -ForegroundColor $C_YELLOW
        $fPattern = Join-Path $PENDING "*.md"
        $files = Get-ChildItem $fPattern -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            Show-Entry "pending" $f.Name
        }
    }
}

function Action-History {
    $manifest = Get-Manifest
    $entries = $manifest.entries | Sort-Object -Property created -Descending
    Write-Host "`nOperation History" -ForegroundColor $C_MAGENTA
    Write-Host ("=" * 40) -ForegroundColor $C_DKGRAY
    if ($entries.Count -eq 0) {
        Write-Host "  No records yet" -ForegroundColor $C_GRAY
        return
    }
    $statusLabels = @{ pending = "[PENDING]"; approved = "[APPRVD]"; rejected = "[REJECT]"; merged = "[MERGED]" }
    foreach ($e in $entries) {
        $label = $(if ($statusLabels[$e.status]) { $statusLabels[$e.status] } else { "[?] $($e.status)" })
        Write-Host "  [$($e.id)] $label $($e.submitter) -> $($e.source)" -ForegroundColor $C_WHITE
        Write-Host "           $($e.created)" -ForegroundColor $C_GRAY
        if ($e.reason) { Write-Host "           reason: $($e.reason)" -ForegroundColor $C_DKGRAY }
    }
}

# --- Main ---
switch ($Action.ToLower()) {
    "submit"  { Action-Submit }
    "list"    { Action-List }
    "show"    { Action-Show }
    "review"  { Action-Review }
    "merge"   { Action-Merge }
    "reject"  { Action-Reject }
    "message" { Action-Message }
    "status"  { Action-Status }
    "history" { Action-History }
    default {
        Write-Host "Unknown action. Available: submit, list, show, review, merge, reject, message, status, history" -ForegroundColor $C_RED
    }
}
