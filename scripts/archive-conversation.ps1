<#
╔═══════════════════════════════════════════════════════════════╗
║   小梦对话存档脚本（Windows / PowerShell 单文件版）          ║
║   全部写入 conversations.md，按日期分章节                    ║
║   用法: .\scripts\archive-conversation.ps1 "角色" "消息内容" ║
╚═══════════════════════════════════════════════════════════════╝
#>

param(
    [string]$Role = "",
    [string]$Content = ""
)

$WORKSPACE = Split-Path -Parent $PSScriptRoot
$FILE = Join-Path $WORKSPACE "conversations.md"
$DATE = Get-Date -Format "yyyy-MM-dd"
$TIME = Get-Date -Format "HH:mm"

# 验证参数
if (-not $Role -or -not $Content) {
    Write-Host "❌ 用法: .\scripts\archive-conversation.ps1 <角色> <消息内容>" -ForegroundColor Red
    exit 1
}

# 文件不存在则创建标题
if (-not (Test-Path $FILE)) {
    $header = @"
# 💬 小梦与小余的对话记录

---

"@
    $header | Set-Content $FILE -Encoding UTF8
}

# 检查今天是否已有章节标题
$todaySection = "## 📅 ${DATE}"
$fileContent = Get-Content $FILE -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
$hasToday = $fileContent -match [regex]::Escape($todaySection)

if (-not $hasToday) {
    Add-Content $FILE "`n${todaySection}`n" -Encoding UTF8
}

# 追加对话
$line = "`n- **🕐 ${TIME}** **${Role}：** ${Content}"
Add-Content $FILE $line -Encoding UTF8

Write-Host "✅ 对话已存档 → conversations.md" -ForegroundColor Green
