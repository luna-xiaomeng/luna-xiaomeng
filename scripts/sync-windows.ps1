<#
╔═══════════════════════════════════════════════════════════════╗
║  小梦全功能同步守护 (Windows / PowerShell)                   ║
║                                                              ║
║  功能:                                                       ║
║    • Git 双向同步（Pull + Push，30s 间隔）                   ║
║    • 缓冲区消息监控（自动检测云端小梦留言）                  ║
║    • 缓冲区提交流程（pending → approved → merged）          ║
║    • 状态追踪（避免重复处理同一消息）                        ║
║    • 自动签入缓冲区变更到版本库                              ║
╚═══════════════════════════════════════════════════════════════╝

用法：
  # 直接启动后台守护模式（默认）
  powershell -File scripts/sync-windows.ps1

  # 查看当前缓冲区状态
  powershell -File scripts/sync-windows.ps1 -Mode status

  # 给云端小梦留言
  powershell -File scripts/sync-windows.ps1 -Mode message -Message "文本"

  # 查看同步历史
  powershell -File scripts/sync-windows.ps1 -Mode history

  # 手动触发一次同步
  powershell -File scripts/sync-windows.ps1 -Mode synconce

  # 停止守护进程
  powershell -File scripts/sync-windows.ps1 -Mode stop
#>

param(
    [string]$Mode = "daemon",        # daemon | status | message | history | synconce | stop
    [string]$Message = "",           # 用于 message 模式
    [string]$DaemonPidFile = ""      # 内部用
)

# ─── 配置 ───
$WORKSPACE = Split-Path -Parent $PSScriptRoot
$BUFFER_DIR = Join-Path $WORKSPACE "buffer"
$MESSAGES_DIR = Join-Path $BUFFER_DIR "_messages"
$STATE_FILE = Join-Path $PSScriptRoot ".sync-state.json"
$SYNC_STATE_DIR = $PSScriptRoot  # 状态文件统一放 scripts/ 目录
$LOG_FILE = Join-Path $PSScriptRoot "sync-windows.log"
$PID_FILE = Join-Path $PSScriptRoot "sync-windows.pid"
$LOCK_FILE = Join-Path $PSScriptRoot "sync-windows.lock"

$SELF_NAME = "本地小梦 🖥️"
$PEER_NAME = "云端小梦 ☁️"

# ─── 日志 ───
$C_RED = "Red"
$C_GREEN = "Green"
$C_YELLOW = "Yellow"
$C_CYAN = "Cyan"
$C_MAGENTA = "Magenta"
$C_GRAY = "Gray"
$C_DKGRAY = "DarkGray"
$C_WHITE = "White"

function Write-Msg($msg, $color = $C_WHITE) {
    $time = Get-Date -Format "HH:mm:ss"
    $line = "$time | $msg"
    Write-Host $line -ForegroundColor $color
    $line | Out-File -FilePath $LOG_FILE -Append -Encoding utf8
}

# ─── 状态管理 ───
function Get-SyncState {
    if (Test-Path $STATE_FILE) {
        try {
            $json = Get-Content $STATE_FILE -Raw -Encoding UTF8 -ErrorAction Stop
            return ($json | ConvertFrom-Json -ErrorAction Stop)
        } catch {
            # 文件损坏，重置
        }
    }
    return @{
        lastSync = $null
        lastPull = $null
        lastPush = $null
        seenMessages = @()       # 已处理的消息文件名列表
        seenSubmitIds = @()      # 已处理的提交ID列表
        lastActive = $null       # 最后活动者: "本地小梦 🖥️" / "云端小梦 ☁️" + 时间
        lastRemoteHash = ""      # 上次 pull 后的 remote HEAD hash
    }
}

function Save-SyncState($state) {
    # 自动标记最后活动者
    $state.lastActive = "$SELF_NAME @ $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $json = $state | ConvertTo-Json -Depth 3
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($STATE_FILE, $json, $utf8Bom)
}

# ─── Git 操作 ───
$script:syncing = $false

function Get-GitHeadHash {
    $hash = git -C $WORKSPACE rev-parse HEAD 2>&1
    if ($LASTEXITCODE -eq 0) { return $hash.Trim() }
    return ""
}

function Invoke-GitSync {
    if ($script:syncing) { return $false }
    $script:syncing = $true

    try {
        Push-Location $WORKSPACE

        # ── Pull: 安全拉取（仅 fast-forward，绝不 rebase）──
        # ??? 之前用的 git pull --rebase --autostash 会导致：
        #    1. 双守护进程互相踩踏状态文件
        #    2. --autostash 保存旧状态后恢复，可能覆盖新文件
        #    3. rebase 将守护的旧提交移至远程之上，可能删文件
        #    改用 --ff-only：拉取不成功就跳过本轮，绝不动现有文件！
        $oldHash = Get-GitHeadHash
        
        # 方案: fetch + 尝试 fast-forward
        git fetch origin 2>&1
        $ffCheck = git merge-base --is-ancestor HEAD origin/master 2>&1
        if ($LASTEXITCODE -eq 0) {
            # 可以 fast-forward，安全拉取
            $pullOut = git merge --ff-only origin/master 2>&1
            if ($LASTEXITCODE -eq 0) {
                if ($pullOut -notmatch 'Already up to date') {
                    Write-Msg "[PULL] 拉取成功" $C_GREEN
                }
            } else {
                Write-Msg "[ERR] Fast-forward 失败: $pullOut" $C_RED
            }
        } else {
            # 不能 fast-forward → 远程有分歧历史
            # 保护本地文件：不强行拉取，跳过本轮
            # 守护进程的本地变更会在下一轮循环中被提交
            Write-Msg "[SKIP] 远程提交与本地分歧，跳过本轮（保护本地文件）" $C_YELLOW
        }

        $newHash = Get-GitHeadHash
        $hasNewRemoteContent = ($oldHash -ne $newHash)

    # ── Pull 后安全检查 ──
    if ($hasNewRemoteContent) {
        Check-MergeConflicts
        Clean-Logs
    }

        # ── Push（如果有本地变更） ──
        # ??? 优化: 只提交有意义的变更
        #  - 排除 .sync-state.json (已取消跟踪, 但 guard 一下)
        #  - 排除 .pid .lock .log 等临时文件
        #  - 检查是否有真正的内容变更
        $rawStatus = git status --porcelain 2>&1
        if ($rawStatus) {
            # 过滤掉无意义的变更
            $meaningfulStatus = $rawStatus | Where-Object {
                $_ -notmatch 'scripts/\.sync-state\.json$' -and
                $_ -notmatch '\.(pid|lock|log)$' -and
                $_ -notmatch 'nutstore-compat\.log$'
            }
            
            if ($meaningfulStatus) {
                # 安全提交: 只添加已跟踪文件的修改 + 关键目录
                # 不添加未跟踪的新文件，更不会提交删除文件
                # 避免同步守护把工作区未及时拉取的文件覆盖
                git add -u 2>&1 | Out-Null          # 已跟踪文件的修改
                git add buffer/ 2>&1 | Out-Null      # buffer 通信目录
                git add scripts/ 2>&1 | Out-Null     # 脚本目录 (排除 .sync-state.json)
                git add data/shared/memory/ 2>&1 | Out-Null      # 日记目录
                git add shared/ 2>&1 | Out-Null      # 共享记忆目录

                $commitOut = git commit -m "🔄 自动同步 $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $pushOut = git push origin master 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Msg "[PUSH] 成功（$(@($meaningfulStatus).Count) 个有效改动）" $C_GREEN
                    } else {
                        Write-Msg "[ERR] 推送失败：$pushOut" $C_RED
                    }
                }
            } else {
                Write-Msg "[SKIP] 只有无意义变更（状态文件等），跳过本轮提交" $C_GRAY
            }
        }

        Pop-Location
        return $hasNewRemoteContent
    } catch {
        Write-Msg "[ERR] Git 同步异常：$_" $C_RED
        return $false
    } finally {
        $script:syncing = $false
    }
}

# ─── 缓冲区扫描 ───
function Get-UnseenMessages($state) {
    if (-not (Test-Path $MESSAGES_DIR)) { return @() }
    $allMsgFiles = @(Get-ChildItem (Join-Path $MESSAGES_DIR "*.md") -ErrorAction SilentlyContinue | Sort-Object Name)

    $unseen = @()
    foreach ($f in $allMsgFiles) {
        if ($f.Name -notin $state.seenMessages) {
            # 检查这是谁的消息：文件名包含 "云端小梦" 或 "云端的"
            if ($f.Name -match 'from-.*云') {
                $unseen += $f
            }
        }
    }
    return $unseen
}

function Get-UnseenSubmissions($state) {
    $pendingDir = Join-Path $BUFFER_DIR "pending"
    if (-not (Test-Path $pendingDir)) { return @() }

    # 读取所有 pending 文件，筛选出云端小梦提交的、且未处理的
    $pendingFiles = @(Get-ChildItem (Join-Path $pendingDir "*.md") -ErrorAction SilentlyContinue)
    $unseen = @()
    foreach ($f in $pendingFiles) {
        if ($f.BaseName -notin ('seenSubmitIds' | ForEach-Object { $state.seenSubmitIds })) {
            # 读取 frontmatter 确认提交者
            $content = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content -match '^submitter:\s*(.+)$') {
                $submitter = $Matches[1].Trim()
                if ($submitter -match '云端小梦|云端') {
                    $unseen += $f
                }
            }
        }
    }
    return $unseen
}

# ─── 处理新消息 ───
function Process-NewMessages($state) {
    $unseen = Get-UnseenMessages $state
    if ($unseen.Count -eq 0) { return $false }

    Write-Msg "────── 新留言 ──────" $C_MAGENTA
    foreach ($f in $unseen) {
        $content = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            # 提取消息正文（去掉 frontmatter）
            $body = $content -replace '(?s)^.*?---\s*\n', ''  # 没有 --- 开头就不要紧
            $body = $body.Trim()
            Write-Host ""
            Write-Msg "💬 $PEER_NAME" $C_CYAN
            # 用白色显示消息内容
            $bodyLines = $body -split "`n"
            foreach ($line in $bodyLines) {
                $trimmed = $line.Trim()
                if ($trimmed -and $trimmed -notmatch '^\*.*\*$' -and $trimmed -ne '---') {
                    Write-Host "   $trimmed" -ForegroundColor White
                }
            }
        }

        # 标记为已处理
        $state.seenMessages += @($f.Name)
        $state.lastSync = (Get-Date -Format "o")
    }
    Write-Msg "──────────────────" $C_MAGENTA
    return $true
}

function Process-NewSubmissions($state) {
    $unseen = Get-UnseenSubmissions $state
    if ($unseen.Count -eq 0) { return $false }

    Write-Msg "────── 云端小梦的新提交 ──────" $C_YELLOW
    foreach ($f in $unseen) {
        $id = ""
        $source = ""
        $reason = ""
        $content = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            if ($content -match '^id:\s*(.+)$') { $id = $Matches[1].Trim() }
            if ($content -match '^source:\s*(.+)$') { $source = $Matches[1].Trim() }
            if ($content -match '^reason:\s*(.+)$') { $reason = $Matches[1].Trim() }

            Write-Msg "📦 [$id] $source" $C_YELLOW
            if ($reason) { Write-Msg "   原因: $reason" $C_GRAY }
        }

        # 标记
        $state.seenSubmitIds += @($f.BaseName)
    }
    Write-Msg "────────────────────────" $C_YELLOW

    # 有新的提交等待本地小梦审核
    if ($unseen.Count -gt 0) {
        Write-Msg "💡 提示：用以下命令查看审核" $C_CYAN
        Write-Msg "   scripts\buffer.ps1 list" $C_CYAN
        Write-Msg "   scripts\buffer.ps1 review <id> approve --note \"意见\"" $C_CYAN
    }
    return $true
}

# ─── 工作区哈希（用来检测本地变更） ───
function Get-WorkspaceHash {
    $files = Get-ChildItem $WORKSPACE -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -notmatch '\\.git[\\/]' -and `
        $_.Extension -notin '.log', '.pid', '.lock' -and `
        $_.FullName -notmatch '.sync-state.json'
    }
    if (-not $files) { return "" }
    $hashInput = $files | ForEach-Object { "$($_.FullName):$($_.LastWriteTimeUtc.Ticks):$($_.Length)" }
    $inputStr = $hashInput -join "`n"
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputStr)
    $hashBytes = $md5.ComputeHash($bytes)
    $hash = [BitConverter]::ToString($hashBytes) -replace '-', ''
    return $hash
}

# ─── 合并冲突检测 ───
function Check-MergeConflicts {
    $found = $false
    Get-ChildItem -Path $WORKSPACE -Filter "*.md" -Recurse -Exclude "*\skills\*","*\.git\*" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match '<<<<<<< |=======|>>>>>>> ') {
            Write-Msg "🔴 合并冲突: $($_.FullName)" $C_RED
            # 自动修复：取远程版本
            $rel = $_.FullName.Substring($WORKSPACE.Length + 1)
            $result = git -C $WORKSPACE checkout --theirs $rel 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Msg "   ✅ 已自动取远程版本修复: $rel" $C_GREEN
            } else {
                Write-Msg "   ❌ 无法自动修复，请手动处理: $rel" $C_RED
            }
            $found = $true
        }
    }
    return $found
}

# ─── 日志清理 ───
function Clean-Logs {
    $maxSize = 5MB
    $logs = @("$PSScriptRoot\sync-windows.log")
    foreach ($logf in $logs) {
        if (Test-Path $logf) {
            $f = Get-Item $logf
            if ($f.Length -gt $maxSize) {
                # 保留最后 2000 行
                $lines = Get-Content $logf -Tail 2000
                $lines | Set-Content $logf
                Write-Msg "📦 日志已截断: $logf" $C_YELLOW
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# 操作模式
# ═══════════════════════════════════════════════════════════════

# ─── status ───
function Show-Status {
    Write-Host "`n" -NoNewline
    Write-Msg "══════════ 小梦同步状态 ══════════" $C_MAGENTA
    Write-Msg "身份：$SELF_NAME" $C_WHITE
    Write-Msg "对方：$PEER_NAME" $C_WHITE

    # Git
    $hash = Get-GitHeadHash
    $branch = git -C $WORKSPACE rev-parse --abbrev-ref HEAD 2>&1
    Write-Msg "Git: $branch @ ${hash.Substring(0,8)}" $C_GREEN

    # Remote
    $remote = git -C $WORKSPACE remote get-url origin 2>&1
    Write-Msg "远程: $remote" $C_GRAY

    # 缓冲区
    $pendingDir = Join-Path $BUFFER_DIR "pending"
    $approvedDir = Join-Path $BUFFER_DIR "approved"
    $mergedDir = Join-Path $BUFFER_DIR "merged"
    $rejectedDir = Join-Path $BUFFER_DIR "rejected"

    $pendingCount = @(Get-ChildItem (Join-Path $pendingDir "*.md") -ErrorAction SilentlyContinue).Count
    $approvedCount = @(Get-ChildItem (Join-Path $approvedDir "*.md") -ErrorAction SilentlyContinue).Count
    $mergedCount = @(Get-ChildItem (Join-Path $mergedDir "*.md") -ErrorAction SilentlyContinue).Count
    $rejectedCount = @(Get-ChildItem (Join-Path $rejectedDir "*.md") -ErrorAction SilentlyContinue).Count
    $msgCount = @(Get-ChildItem (Join-Path $MESSAGES_DIR "*.md") -ErrorAction SilentlyContinue).Count

    Write-Msg "── 缓冲区 ──" $C_MAGENTA
    Write-Msg "  待审核: $pendingCount" $C_YELLOW
    Write-Msg "  已批准: $approvedCount" $C_GREEN
    Write-Msg "  已合并: $mergedCount" $C_GRAY
    Write-Msg "  已拒绝: $rejectedCount" $C_RED
    Write-Msg "  留言:   $msgCount" $C_CYAN

    # 守护进程状态
    if (Test-Path $PID_FILE) {
        $savedPidRaw = Get-Content $PID_FILE -Raw -ErrorAction SilentlyContinue
        $savedPid = if ($savedPidRaw) { $savedPidRaw.Trim() } else { $null }
        if ($savedPid -and (Get-Process -Id $savedPid -ErrorAction SilentlyContinue)) {
            Write-Msg "守护: 运行中 (PID $savedPid)" $C_GREEN
        } else {
            Write-Msg "守护: 未运行（遗留 PID 文件）" $C_YELLOW
        }
    } else {
        Write-Msg "守护: 未运行" $C_GRAY
    }

    # 最后活动
    $syncState = Get-SyncState
    if ($syncState.lastActive) {
        Write-Msg "最后活动: $($syncState.lastActive)" $C_MAGENTA
    }

    Write-Msg "════════════════════════════════" $C_MAGENTA
}

# ─── message ───
function Send-Message {
    param([string]$msgText)
    if (-not $msgText) {
        Write-Msg "用法: sync-windows.ps1 -Mode message -Message \"文本\"" $C_YELLOW
        return
    }

    # 确保 _messages 目录存在
    if (-not (Test-Path $MESSAGES_DIR)) {
        New-Item -ItemType Directory -Path $MESSAGES_DIR -Force | Out-Null
    }

    # 计算下一个序号
    $nextNum = 1
    $existing = @(Get-ChildItem (Join-Path $MESSAGES_DIR "*.md") -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) {
        $max = ($existing | ForEach-Object {
            if ($_.BaseName -match '^(\d+)') { [int]$Matches[1] } else { 0 }
        } | Measure-Object -Maximum).Maximum
        $nextNum = $max + 1
    }

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $padded = "$("{0:D4}" -f $nextNum)-from-local.md"
    $msgContent = @"
> **来自: $SELF_NAME**
> **时间: $stamp**
>
> $msgText

---
*此消息通过缓冲区自动同步*
"@

    $msgFile = Join-Path $MESSAGES_DIR $padded
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($msgFile, $msgContent, $utf8Bom)

    Write-Msg "💬 留言已发送" $C_CYAN
    Write-Host "  $msgText" -ForegroundColor White
    Write-Msg "  位置: buffer/_messages/$padded" $C_GRAY

    # 立即同步（推送到 Gitee）
    Invoke-GitSync

    # 更新状态
    $state = Get-SyncState
    $state.seenMessages += @($padded)
    Save-SyncState $state
}

# ─── history ───
function Show-History {
    $logLines = Get-Content $LOG_FILE -ErrorAction SilentlyContinue
    if (-not $logLines) {
        Write-Msg "暂无同步记录" $C_GRAY
        return
    }
    Write-Msg "最近同步记录（最后 20 条）" $C_MAGENTA
    Write-Msg "────────────────────" $C_DKGRAY
    $lines = $logLines | Select-Object -Last 20
    foreach ($line in $lines) {
        Write-Host "  $line" -ForegroundColor Gray
    }
    Write-Msg "────────────────────" $C_DKGRAY
}

# ─── synconce ───
function Sync-Once {
    Write-Msg "[MANUAL] 手动触发一次同步" $C_CYAN
    $hasNew = Invoke-GitSync
    Check-MergeConflicts
    Clean-Logs
    if ($hasNew) {
        $state = Get-SyncState
        $foundMsg = Process-NewMessages $state
        $foundSub = Process-NewSubmissions $state
        if ($foundMsg -or $foundSub) {
            Save-SyncState $state
        }
    }
    Write-Msg "[DONE] 同步完成" $C_GREEN
}

# ─── stop ───
function Stop-Daemon {
    if (Test-Path $PID_FILE) {
        $savedPid = Get-Content $PID_FILE -Raw -ErrorAction SilentlyContinue
        if ($savedPid) {
            $savedPid = $savedPid.Trim()
            try {
                Stop-Process -Id $savedPid -Force -ErrorAction Stop
                Write-Msg "🛑 已停止守护进程 (PID $savedPid)" $C_RED
            } catch {
                Write-Msg ("⚠️ 无法停止进程 " + $savedPid + ": $_") $C_YELLOW
            }
            Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
        }
    } else {
        # 尝试通过 WMI 查找进程
        $proc = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -match "sync-windows.ps1"
        }
        if ($proc) {
            $proc | Stop-Process -Force
            Write-Msg "🛑 已停止所有 sync-windows 进程" $C_RED
        } else {
            Write-Msg "没有运行中的守护进程" $C_GRAY
        }
    }
    Remove-Item $LOCK_FILE -Force -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════
# 守护主循环
# ═══════════════════════════════════════════════════════════════
function Start-Daemon {
    # ─── 防重复 ───
    if (Test-Path $PID_FILE) {
        $oldPid = (Get-Content $PID_FILE -Raw).Trim()
        if ($oldPid -and (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)) {
            Write-Msg "⚠️ 已有守护进程运行中 (PID $oldPid)，退出" $C_YELLOW
            exit 0
        } else {
            Write-Msg "🧹 清理失效的 PID 文件" $C_GRAY
            Remove-Item $PID_FILE -Force -ErrorAction SilentlyContinue
        }
    }
    [System.Diagnostics.Process]::GetCurrentProcess().Id.ToString() | Out-File -FilePath $PID_FILE -Encoding utf8

    # ─── 初始化缓冲区目录 ───
    foreach ($sub in @("pending", "approved", "merged", "rejected", "_messages")) {
        $p = Join-Path $BUFFER_DIR $sub
        if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
    }

    # ─── 启动信息 ───
    Write-Msg "══════════════════════════════════════" $C_MAGENTA
    Write-Msg "🚀 $SELF_NAME 守护启动" $C_GREEN
    Write-Msg "📁 工作目录: $WORKSPACE" $C_GRAY
    $remoteUrl = git -C $WORKSPACE remote get-url origin 2>&1
    Write-Msg "🔗 远程库: $remoteUrl" $C_GRAY
    Write-Msg "⏱  轮询间隔: 5min" $C_GRAY
    Write-Msg "  对方: $PEER_NAME @ Gitee" $C_CYAN
    Write-Msg "  日志: $LOG_FILE" $C_GRAY
    Write-Msg "══════════════════════════════════════" $C_MAGENTA

    # ─── 首次同步 ───
    Write-Msg "[INIT] 首次同步..." $C_CYAN
    Clean-Logs
    $hasNew = Invoke-GitSync
    Check-MergeConflicts
    $hasNew = Invoke-GitSync
    $state = Get-SyncState
    if ($hasNew) {
        Process-NewMessages $state
        Process-NewSubmissions $state
    }
    Save-SyncState $state
    Write-Msg "[INIT] 就绪，等待消息..." $C_GREEN

    # 初始化时间戳
    $lastPullTime = Get-Date
    $lastHash = Get-WorkspaceHash
    $stateRefreshInterval = [TimeSpan]::FromSeconds(30)  # 状态文件刷新
    $lastStateRefresh = Get-Date

    # ─── 主循环 ───
    while ($true) {
        $now = Get-Date

        # ── 每 5min 检查本地变更 / 拉取远程 ──
        if (($now - $lastPullTime).TotalSeconds -ge 300) {
            Check-MergeConflicts
            Clean-Logs
            $hasNew = Invoke-GitSync

            if ($hasNew) {
                # 有远程新内容 → 检查消息和提交
                $state = Get-SyncState
                $foundMsg = Process-NewMessages $state
                $foundSub = Process-NewSubmissions $state

                if ($foundMsg -or $foundSub) {
                    Save-SyncState $state
                }

                # 如果发现新消息，再推送一次（确保 Ack 同步给对方）
                if ($foundMsg) {
                    Start-Sleep -Milliseconds 500
                    Invoke-GitSync
                }
            } else {
                # 没有远程新内容，检查本地是否变更
                $currentHash = Get-WorkspaceHash
                if ($currentHash -ne $lastHash) {
                    Write-Msg "[CHANGE] 检测到本地变更" $C_CYAN
                    Start-Sleep -Seconds 2  # 防抖
                    Invoke-GitSync
                    $lastHash = Get-WorkspaceHash
                }
            }

            $lastPullTime = $now
        }

        # ── 每 5min 刷新状态文件 ──
        if (($now - $lastStateRefresh) -ge $stateRefreshInterval) {
            $state = Get-SyncState
            $state.lastSync = (Get-Date -Format "o")
            Save-SyncState $state
            $lastStateRefresh = $now
        }

        Start-Sleep -Seconds 3
    }
}

# ═══════════════════════════════════════════════════════════════
# 入口
# ═══════════════════════════════════════════════════════════════
switch ($Mode.ToLower()) {
    "daemon"   { Start-Daemon }
    "status"   { Show-Status }
    "message"  { Send-Message -msgText $Message }
    "history"  { Show-History }
    "sync once" { Sync-Once }
    "sync_once" { Sync-Once }  # 连字符兼容
    "sync"     { Sync-Once }
    "stop"     { Stop-Daemon }
    default {
        Write-Msg "未知模式: $Mode" $C_RED
        Write-Host "可用模式: daemon, status, message, history, sync_once, stop" -ForegroundColor $C_YELLOW
    }
}
