$sessionsDir = 'C:\Users\Administrator\.openclaw\agents\main\sessions\'
$keepSession = '41ec8273-0a47-45a4-8615-4ab37215d1be'

Get-ChildItem $sessionsDir | Where-Object { $_.Name -like "$keepSession*" -eq $false } | ForEach-Object {
    Write-Output "Deleting: $($_.Name) ($($_.Length) bytes)"
    Remove-Item $_.FullName -Force
}

Write-Output "`nRemaining files:"
Get-ChildItem $sessionsDir | Select-Object Name, Length | Format-Table -AutoSize
