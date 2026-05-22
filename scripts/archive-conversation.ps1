<#
╔═══════════════════════════════════════════════════════════════╗
║   小梦对话存档脚本（Windows / PowerShell 单文件版）          ║
║   全部写入 conversations.md，按日期分章节                    ║
║   用法: .\scripts\archive-conversation.ps1 <角色> <消息>     ║
║   角色可选: 小余 / 小梦(本地) / 小梦(云端)                  ║
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
    Write-Host "Usage: .\scripts\archive-conversation.ps1 <Role> <Message>" -ForegroundColor Yellow
    Write-Host "  Role: 小余 / 小梦(本地) / 小梦(云端)" -ForegroundColor Yellow
    exit 1
}

# 文件不存在则创建标题
if (-not (Test-Path $FILE)) {
    $header = @"
# 💬 小梦与小余的对话记录

---

"@
    [System.IO.File]::WriteAllText($FILE, $header, [System.Text.UTF8Encoding]::new($true))
}

# 读取文件内容
$content = [System.IO.File]::ReadAllText($FILE, [System.Text.UTF8Encoding]::new($true))

# 检查今天是否已有章节标题
$todaySection = "## 📅 ${DATE}"
if (-not $content.Contains($todaySection)) {
    # 追加新章节
    $content += "`n${todaySection}`n"
    [System.IO.File]::WriteAllText($FILE, $content, [System.Text.UTF8Encoding]::new($true))
}

# 追加对话（用 System.IO 确保 UTF-8 编码正确）
$line = "`n- **🕐 ${TIME}** **${Role}：** ${Content}"
[System.IO.File]::AppendAllText($FILE, $line, [System.Text.UTF8Encoding]::new($true))

Write-Host "✅ 对话已存档 → conversations.md" -ForegroundColor Green
