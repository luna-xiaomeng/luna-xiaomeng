Write-Host "正在清理 workspace 中的 ReparsePoint..."
$count = 0
$fail = 0
$root = "C:\Users\Administrator\.openclaw\workspace"
Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint } | ForEach-Object {
    try {
        fsutil reparsepoint delete $_.FullName 2>&1 | Out-Null
        $count++
        Write-Host "  ✅ $($_.FullName)"
    } catch {
        $fail++
    }
}
Write-Host "完成: 清理 $count 个, 失败 $fail 个"
# Also check OpenClaw agents session files
Get-ChildItem "C:\Users\Administrator\.openclaw\agents" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint } | ForEach-Object {
    try {
        fsutil reparsepoint delete $_.FullName 2>&1 | Out-Null
        $count++
    } catch { $fail++ }
}
Write-Host "总计: 清理 $count 个, 失败 $fail 个"
if ($count -gt 0 -or $fail -gt 0) {
    Read-Host "按回车确认"
}