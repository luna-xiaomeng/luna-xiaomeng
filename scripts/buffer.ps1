<#
╔═══════════════════════════════════════════════════════════════╗
║   🗂️ 小梦缓冲区管理工具 (Windows / PowerShell)              ║
║   本地小梦 ↔ 云端小梦 的工作交流区                           ║
╚═══════════════════════════════════════════════════════════════╝
用法:
  .\scripts\buffer.ps1 submit <file> [--reason "说明"] [--target 目标路径]
  .\scripts\buffer.ps1 list [--all]
  .\scripts\buffer.ps1 show <id>
  .\scripts\buffer.ps1 review <id> approve|reject [--note "意见"]
  .\scripts\buffer.ps1 merge <id>
  .\scripts\buffer.ps1 reject <id> [--note "原因"]
  .\scripts\buffer.ps1 message <文本>
  .\scripts\buffer.ps1 status
  .\scripts\buffer.ps1 history
#>

param(
    [string]$Action = "status",
    [string]$Id = "",
    [string]$File = "",
    [string]$Reason = "",
    [string]$Target = "",
    [string]$Note = "",
    [string]$Message = "",
    [switch]$All = $false,
    [string]$Decision = ""
)

# ─── 配置 ───
$WORKSPACE = $PSScriptRoot | Split-Path -Parent
$BUFFER = "$WORKSPACE\buffer"
$MANIFEST = "$BUFFER\_manifest.json"
$MESSAGES_DIR = "$BUFFER\_messages"
$PENDING = "$BUFFER\pending"
$APPROVED = "$BUFFER\approved"
$MERGED = "$BUFFER\merged"
$REJECTED = "$BUFFER\rejected"
$SELF_NAME = if ((whoami) -eq "Administrator") { "本地小梦" } else { "本地小梦" }  # 本地 always 本地小梦
$COUNTER_FILE = "$BUFFER\.counter"

# ─── 获取下一个ID ───
function Get-NextId {
    $today = Get-Date -Format "yyyyMMdd"
    $counter = 1
    if (Test-Path $COUNTER_FILE) {
        $last = Get-Content $COUNTER_FILE -Raw -ErrorAction SilentlyContinue
        if ($last -match "$today-(\d+)") {
            $counter = [int]$Matches[1] + 1
        }
    }
    $id = "buf-$today-{0:D3}" -f $counter
    Set-Content $COUNTER_FILE $id -NoNewline
    return $id
}

# ─── 读取清单 ───
function Get-Manifest {
    if (Test-Path $MANIFEST) {
        return Get-Content $MANIFEST -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
    }
    return @{ entries = @() }
}

# ─── 保存清单 ───
function Save-Manifest($manifest) {
    $manifest.entries = @($manifest.entries | Sort-Object -Property created -Descending)
    $json = $manifest | ConvertTo-Json -Depth 3
    $json | Set-Content $MANIFEST -Encoding UTF8
}

# ─── 生成提交文件 ───
function New-BufferFile($id, $sourceFile, $content) {
    $today = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $filename = $sourceFile -replace '[/\\:]', '-'
    $outName = "$id-$filename.md"
    
    # 元数据头 + 内容
    $header = @"
---
id: $id
submitter: 本地小梦
source: $sourceFile
target: $Target
created: $today
status: pending
priority: normal
reason: $Reason
---

"@
    
    $fullContent = $header + $content
    
    # 写入 pending
    $outPath = Join-Path $PENDING $outName
    $fullContent | Set-Content $outPath -Encoding UTF8
    return $outPath, $outName
}

# ─── 显示一个条目 ───
function Show-Entry($dir, $file) {
    $path = Join-Path $BUFFER $dir $file
    if (-not (Test-Path $path)) { return }
    $content = Get-Content $path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return }
    
    # 解析 frontmatter
    if ($content -match '^---\s*\n(.+?)\n---') {
        $fm = $Matches[1]
        $body = $content -replace '^---\s*\n.*?\n---\s*\n', ''
        # 提取元数据
        $data = @{}
        foreach ($line in $fm -split '\n') {
            if ($line -match '^(\w+):\s*(.*)') {
                $data[$Matches[1]] = $Matches[2]
            }
        }
        return [PSCustomObject]@{
            Id       = $data.id
            Status   = $data.status
            Submitter= $data.submitter
            Source   = $data.source
            Target   = $data.target
            Created  = $data.created
            Reason   = $data.reason
            Priority = $data.priority
            Dir      = $dir
            File     = $file
            Body     = $body.Length -gt 300 ? $body.Substring(0,300) + "…" : $body
        }
    }
    return $null
}

# ─── ACTION: submit ───
function Action-Submit {
    if (-not $File) {
        Write-Host "❌ 请指定要提交的文件" -ForegroundColor Red
        Write-Host "用法: buffer submit <file> [--reason ""说明""]" -ForegroundColor Gray
        return
    }
    $srcPath = Resolve-Path $File -ErrorAction SilentlyContinue
    if (-not $srcPath) {
        Write-Host "❌ 文件不存在: $File" -ForegroundColor Red
        return
    }
    $content = Get-Content $srcPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Host "❌ 无法读取文件: $File" -ForegroundColor Red
        return
    }
    
    $relPath = if ($srcPath.Path -match [regex]::Escape($WORKSPACE)) {
        $srcPath.Path.Substring($WORKSPACE.Length + 1)
    } else {
        $srcPath.Path
    }
    
    $id = Get-NextId
    $outPath, $outName = New-BufferFile $id $relPath $content
    
    # 更新 Manifest
    $manifest = Get-Manifest
    $manifest.entries += @{
        id = $id
        submitter = "本地小梦"
        source = $relPath
        target = if ($Target) { $Target } else { $relPath }
        created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        status = "pending"
        priority = "normal"
        reason = $Reason
        file = "$PENDING/$outName"
    }
    Save-Manifest $manifest
    
    Write-Host "✅ 已提交到缓冲区 [${id}]" -ForegroundColor Green
    Write-Host "   来源: $relPath" -ForegroundColor Cyan
    Write-Host "   位置: buffer/pending/$outName" -ForegroundColor Cyan
    Write-Host "   原因: $(if ($Reason) { $Reason } else { '未说明' })" -ForegroundColor Yellow
    Write-Host "`n⏳ 等待云端小梦审核中..." -ForegroundColor Gray
}

# ─── ACTION: list ───
function Action-List {
    $showAll = $All
    $manifest = Get-Manifest
    
    Write-Host "`n📋 缓冲区清单" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor DarkGray
    
    $dirs = @(
        @{ Name = "pending"; Label = "⏳ 待审核" },
        @{ Name = "approved"; Label = "✅ 已批准" },
        @{ Name = "merged"; Label = "📦 已合并" },
        @{ Name = "rejected"; Label = "❌ 已拒绝" }
    )
    
    foreach ($d in $dirs) {
        $entries = @(Get-ChildItem "$BUFFER/$($d.Name)\*.md" -ErrorAction SilentlyContinue)
        if (-not $showAll -and $d.Name -ne "pending") { continue }
        if ($entries.Count -eq 0) { continue }
        
        Write-Host "`n$($d.Label) ($($entries.Count))" -ForegroundColor $(
            if ($d.Name -eq "pending") { "Yellow" }
            elseif ($d.Name -eq "approved") { "Green" }
            elseif ($d.Name -eq "merged") { "DarkGray" }
            else { "Red" }
        )
        Write-Host "─────────────────────────────────" -ForegroundColor DarkGray
        
        foreach ($entry in $entries) {
            $obj = Show-Entry $d.Name $entry.Name
            if (-not $obj) { continue }
            Write-Host "  [$($obj.Id)] $($obj.Source)" -ForegroundColor White
            Write-Host "        来自: $($obj.Submitter) | $($obj.Created)" -ForegroundColor Gray
            if ($obj.Reason) { Write-Host "        原因: $($obj.Reason)" -ForegroundColor Gray }
            Write-Host ""
        }
    }
    
    if ($showAll -or ($manifest.entries.Count -eq 0)) {
        # 显示对话消息
        $msgs = @(Get-ChildItem "$MESSAGES_DIR\*.md" -ErrorAction SilentlyContinue)
        if ($msgs.Count -gt 0) {
            Write-Host "💬 留言 ($($msgs.Count))" -ForegroundColor Cyan
            Write-Host "─────────────────────────────────" -ForegroundColor DarkGray
            foreach ($m in $msgs) {
                $content = Get-Content $m.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                $preview = if ($content) { $content.Substring(0, [Math]::Min(100, $content.Length)).Trim() } else { "" }
                Write-Host "  [$($m.BaseName)] $preview" -ForegroundColor White
            }
        }
    }
    
    if (-not $showAll) {
        Write-Host "`n💡 提示: 用 --all 查看全部状态" -ForegroundColor DarkGray
    }
}

# ─── ACTION: show ───
function Action-Show {
    if (-not $Id) {
        Write-Host "❌ 请指定 ID，如: buffer show buf-20260521-001" -ForegroundColor Red
        return
    }
    
    # 在所有目录找
    foreach ($dir in @("pending", "approved", "merged", "rejected")) {
        $files = Get-ChildItem "$BUFFER\$dir\*.md" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            if ($f.BaseName -like "$Id*") {
                $content = Get-Content $f.FullName -Raw -Encoding UTF8
                Write-Host "`n🗂️  $($f.Name)" -ForegroundColor Magenta
                Write-Host "═══════════════════════════════════════" -ForegroundColor DarkGray
                Write-Host ""
                Write-Host $content -ForegroundColor White
                return
            }
        }
    }
    Write-Host "❌ 未找到 ID: $Id" -ForegroundColor Red
}

# ─── ACTION: review ───
function Action-Review {
    if (-not $Id -or -not $Decision) {
        Write-Host "❌ 用法: buffer review <id> approve|reject [--note ""意见""]" -ForegroundColor Red
        return
    }
    if ($Decision -notin @("approve", "reject")) {
        Write-Host "❌ 决策必须是 approve 或 reject" -ForegroundColor Red
        return
    }
    
    # 在 pending 找
    $found = $null
    $files = Get-ChildItem "$PENDING\*.md" -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        if ($f.BaseName -like "$Id*") {
            $found = $f
            break
        }
    }
    if (-not $found) {
        Write-Host "❌ 待审核中未找到 ID: $Id（可能已处理）" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $found.FullName -Raw -Encoding UTF8
    $newStatus = if ($Decision -eq "approve") { "approved" } else { "rejected" }
    $targetDir  = if ($Decision -eq "approve") { $APPROVED } else { $REJECTED }
    
    # 更新 frontmatter 中的 status
    $updated = $content -replace '(?m)^status:.*', "status: $newStatus"
    if ($Note) {
        $updated = $updated -replace '(?m)^reviewer:.*', "reviewer: 本地小梦"
        $updated = $updated -replace '(?m)^review_note:.*', "review_note: $Note"
    }
    if ($updated -notmatch '(?m)^reviewer:') {
        $updated = $updated -replace '(?m)^---\s*$', "reviewer: 本地小梦`nreview_note: $Note`n---"
    }
    
    # 写回
    $newPath = Join-Path $targetDir $found.Name
    $updated | Set-Content $newPath -Encoding UTF8
    Remove-Item $found.FullName
    
    # 更新 Manifest
    $manifest = Get-Manifest
    foreach ($entry in $manifest.entries) {
        if ($entry.id -eq $Id) {
            $entry.status = $newStatus
            $entry.file = "$targetDir\$($found.Name)"
        }
    }
    Save-Manifest $manifest
    
    $emoji = if ($Decision -eq "approve") { "✅" } else { "❌" }
    $actionText = if ($Decision -eq "approve") { "批准" } else { "拒绝" }
    Write-Host "$emoji 已$actionText [$Id]" -ForegroundColor Green
    if ($Note) { Write-Host "   意见: $Note" -ForegroundColor Yellow }
    Write-Host "   文件已移至 buffer/$newStatus/" -ForegroundColor Cyan
}

# ─── ACTION: merge ───
function Action-Merge {
    if (-not $Id) {
        Write-Host "❌ 用法: buffer merge <id>" -ForegroundColor Red
        return
    }
    
    $found = $null
    $files = Get-ChildItem "$APPROVED\*.md" -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        if ($f.BaseName -like "$Id*") {
            $found = $f
            break
        }
    }
    if (-not $found) {
        Write-Host "❌ 已批准中未找到 ID: $Id" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $found.FullName -Raw -Encoding UTF8
    
    # 解析 target path
    $targetPath = ""
    if ($content -match '(?m)^target:\s*(.*)') {
        $targetPath = $Matches[1].Trim()
    }
    if (-not $targetPath) {
        if ($content -match '(?m)^source:\s*(.*)') {
            $targetPath = $Matches[1].Trim()
        }
    }
    if (-not $targetPath) {
        Write-Host "❌ 无法解析目标路径" -ForegroundColor Red
        return
    }
    
    # 提取正文（去掉 frontmatter）
    $body = $content -replace '^---\s*\n.*?\n---\s*\n', ''
    if (-not $body) {
        Write-Host "❌ 文件内容为空" -ForegroundColor Red
        return
    }
    
    $absTarget = if ([System.IO.Path]::IsPathRooted($targetPath)) {
        $targetPath
    } else {
        Join-Path $WORKSPACE $targetPath
    }
    
    # 备份原文件
    if (Test-Path $absTarget) {
        $bakPath = "$absTarget.bak"
        Copy-Item $absTarget $bakPath -Force
        Write-Host "💾 已备份原文件到 $bakPath" -ForegroundColor DarkGray
    }
    
    # 写入目标
    $body | Set-Content $absTarget -Encoding UTF8
    Write-Host "📝 已写入: $absTarget" -ForegroundColor Green
    
    # 更新 frontmatter
    $updated = $content -replace '(?m)^status:.*', "status: merged"
    $updated = $updated -replace '(?m)^merged_at:.*', "merged_at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    if ($updated -notmatch '(?m)^merged_at:') {
        $updated = $updated -replace '(?m)^---\s*$', "merged_at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n---"
    }
    
    # 移到 merged
    $mergedPath = Join-Path $MERGED $found.Name
    $updated | Set-Content $mergedPath -Encoding UTF8
    Remove-Item $found.FullName
    
    # 更新 Manifest
    $manifest = Get-Manifest
    foreach ($entry in $manifest.entries) {
        if ($entry.id -eq $Id) {
            $entry.status = "merged"
            $entry.merged_at = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            $entry.file = "$MERGED\$($found.Name)"
        }
    }
    Save-Manifest $manifest
    
    Write-Host "✅ [$Id] 已合并完成并归档" -ForegroundColor Green
}

# ─── ACTION: reject ───
function Action-Reject {
    if (-not $Id) {
        Write-Host "❌ 用法: buffer reject <id> [--note ""原因""]" -ForegroundColor Red
        return
    }
    
    $found = $null
    # 也可能在 pending 直接拒绝
    foreach ($dir in @("pending", "approved")) {
        $files = Get-ChildItem "$BUFFER\$dir\*.md" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            if ($f.BaseName -like "$Id*") {
                $found = $f
                break
            }
        }
        if ($found) { break }
    }
    if (-not $found) {
        Write-Host "❌ 未找到 ID: $Id" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $found.FullName -Raw -Encoding UTF8
    $updated = $content -replace '(?m)^status:.*', "status: rejected"
    if ($Note) {
        $updated = $updated -replace '(?m)^reviewer:.*', "reviewer: 本地小梦"
        $updated = $updated -replace '(?m)^review_note:.*', "review_note: $Note"
    }
    if ($updated -notmatch '(?m)^reviewer:') {
        $updated = $updated -replace '(?m)^---\s*$', "reviewer: 本地小梦`nreview_note: $Note`n---"
    }
    
    $rejectPath = Join-Path $REJECTED $found.Name
    $updated | Set-Content $rejectPath -Encoding UTF8
    Remove-Item $found.FullName
    
    $manifest = Get-Manifest
    foreach ($entry in $manifest.entries) {
        if ($entry.id -eq $Id) {
            $entry.status = "rejected"
            $entry.file = "$REJECTED\$($found.Name)"
        }
    }
    Save-Manifest $manifest
    
    Write-Host "❌ 已拒绝 [$Id]" -ForegroundColor Red
    if ($Note) { Write-Host "   原因: $Note" -ForegroundColor Yellow }
    Write-Host "   文件已移至 buffer/rejected/" -ForegroundColor DarkGray
}

# ─── ACTION: message ───
function Action-Message {
    if (-not $Message) {
        Write-Host "❌ 用法: buffer message <文本>" -ForegroundColor Red
        return
    }
    
    # 获取序号
    $nextNum = 1
    $existing = @(Get-ChildItem "$MESSAGES_DIR\*.md" -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) {
        $lastNum = $existing | ForEach-Object {
            if ($_.BaseName -match '^(\d+)') { [int]$Matches[1] } else { 0 }
        } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
        $nextNum = $lastNum + 1
    }
    
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fromWho = "本地小梦 💻"
    
    $msgContent = @"
> **来自: $fromWho**
> **时间: $stamp**
> 
> $Message

---
*此消息通过缓冲区自动同步*
"@
    
    $fileName = "$("{0:D4}" -f $nextNum)-from-本地小梦.md"
    $msgFile = Join-Path $MESSAGES_DIR $fileName
    $msgContent | Set-Content $msgFile -Encoding UTF8
    
    Write-Host "💬 留言已发送" -ForegroundColor Cyan
    Write-Host "   来自: 本地小梦" -ForegroundColor White
    Write-Host "   内容: $Message" -ForegroundColor White
    Write-Host "   位置: buffer/_messages/$fileName" -ForegroundColor DarkGray
}

# ─── ACTION: status ───
function Action-Status {
    $pendingCount  = @(Get-ChildItem "$PENDING\*.md" -ErrorAction SilentlyContinue).Count
    $approvedCount = @(Get-ChildItem "$APPROVED\*.md" -ErrorAction SilentlyContinue).Count
    $mergedCount   = @(Get-ChildItem "$MERGED\*.md" -ErrorAction SilentlyContinue).Count
    $rejectedCount = @(Get-ChildItem "$REJECTED\*.md" -ErrorAction SilentlyContinue).Count
    $msgCount      = @(Get-ChildItem "$MESSAGES_DIR\*.md" -ErrorAction SilentlyContinue).Count
    
    Write-Host "`n🗂️  缓冲区状态" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  ⏳ 待审核: $pendingCount  件" -ForegroundColor Yellow
    Write-Host "  ✅ 已批准: $approvedCount  件" -ForegroundColor Green
    Write-Host "  📦 已合并: $mergedCount  件" -ForegroundColor DarkGray
    Write-Host "  ❌ 已拒绝: $rejectedCount  件" -ForegroundColor Red
    Write-Host "  💬 留言:   $msgCount  条" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  我是: 🖥️ 本地小梦 (Windows)" -ForegroundColor White
    Write-Host "  对方: ☁️ 云端小梦 (阿里云)" -ForegroundColor White
    Write-Host "═══════════════════════════════════════" -ForegroundColor DarkGray
    
    if ($pendingCount -gt 0) {
        Write-Host "`n📋 待审核列表:" -ForegroundColor Yellow
        $files = Get-ChildItem "$PENDING\*.md" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $obj = Show-Entry "pending" $f.Name
            if ($obj) {
                Write-Host "  [$($obj.Id)] $($obj.Source) ← $($obj.Submitter)" -ForegroundColor White
            }
        }
    }
}

# ─── ACTION: history ───
function Action-History {
    $manifest = Get-Manifest
    $entries = $manifest.entries | Sort-Object -Property created -Descending
    
    Write-Host "`n📜 缓冲区操作历史" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor DarkGray
    
    if ($entries.Count -eq 0) {
        Write-Host "  暂无记录" -ForegroundColor Gray
        return
    }
    
    $statusLabels = @{
        "pending"  = "⏳ 待审核"
        "approved" = "✅ 已批准"
        "rejected" = "❌ 已拒绝"
        "merged"   = "📦 已合并"
    }
    
    foreach ($e in $entries) {
        $label = $statusLabels[$e.status]
        if (-not $label) { $label = "❓ $($e.status)" }
        Write-Host "  [$($e.id)] $label $($e.submitter) → $($e.source)" -ForegroundColor White
        Write-Host "           $($e.created)" -ForegroundColor Gray
        if ($e.reason) { Write-Host "           原因: $($e.reason)" -ForegroundColor DarkGray }
    }
}

# ─── Main ───
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
        Write-Host "❓ 未知操作: $Action" -ForegroundColor Red
        Write-Host "可用操作: submit, list, show, review, merge, reject, message, status, history" -ForegroundColor Gray
    }
}
