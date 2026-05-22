import pathlib
path = pathlib.Path('C:/Users/Administrator/.openclaw/workspace/scripts/maintain-soul.ps1')
content = path.read_text('utf-8')
# Replace the emoji-based date header with a simple marker
content = content.replace(
    '$todayStr = "\\U0001f4c5 " + (Get-Date -Format "yyyy-MM-dd")',
    '$todaySection = "## [DATE] " + (Get-Date -Format "yyyy-MM-dd")'
)
content = content.replace(
    '$todayStr = ([char]0x1F4C5) + " " + (Get-Date -Format "yyyy-MM-dd")',
    '$todaySection = "## [DATE] " + (Get-Date -Format "yyyy-MM-dd")'
)
# Update the reference too
content = content.replace('$conv.Contains($todayStr)', '$conv.Contains($todaySection)')
content = content.replace('$conv -split $todayStr', '$conv -split $todaySection')
path.write_text(content, 'utf-8')
print('Done')
# Count lines
lines = content.split('\n')
print(f'File: {len(lines)} lines')
