"""
全面审查xiaomeng-workspace仓库的所有文件
检查项:
  - 过时的路径引用(broadcast/, conversations/, backup-xiaomeng.ps1在根目录)
  - 残余的"主人"引用
  - 已无效的脚本
  - 内容与当前结构不匹配
"""
import pathlib, os

WORKSPACE = r'C:\Users\Administrator\.openclaw\workspace'
SKIP_DIRS = {'.git', 'node_modules', 'skills', 'buffer/_messages', 'buffer/merged', 'buffer/pending', 'buffer/approved', 'buffer/rejected', '_messages'}
SKIP_FILES = {'.gitignore', '.sync-state.json', '.counter', 'fix_script.py', 'test_concat.py', 'tree.json', 'yikz_repos.json'}
BINARY_EXTS = {'.mp4', '.mp3', '.png', '.jpg', '.svg', '.json', '.lock', '.log'}

issues = []

def should_skip(path):
    rel = path.relative_to(WORKSPACE)
    parts = rel.parts
    for skip in SKIP_DIRS:
        if skip in parts:
            return True
    if path.name in SKIP_FILES:
        return True
    if path.suffix in BINARY_EXTS:
        return True
    return False

# Iterate all files
for root, dirs, files in os.walk(WORKSPACE):
    for f in files:
        path = pathlib.Path(root) / f
        if should_skip(path):
            continue
        rel = path.relative_to(WORKSPACE)
        
        # Read content
        try:
            content = path.read_text('utf-8')
        except:
            try:
                content = path.read_text('gbk')
            except:
                continue
        
        # Check 1: Has "主人" 
        if '主人' in content:
            count = content.count('主人')
            issues.append(f'[主人] {rel}: {count}处')
        
        # Check 2: References old broadcast/ directory
        if 'broadcast/' in content and 'broadcast/' not in str(rel):
            issues.append(f'[旧路径] {rel}: 引用旧 broadcast/ 目录')
        
        # Check 3: References old conversations/ directory
        if 'conversations/' in content and 'conversations/' not in str(rel):
            issues.append(f'[旧路径] {rel}: 引用旧 conversations/ 目录')
        
        # Check 4: References backup-xiaomeng.ps1 without scripts/
        if 'backup-xiaomeng.ps1' in content and 'scripts/backup' not in content:
            # Only flag if file isn't already in scripts/
            if 'scripts/' not in str(rel):
                issues.append(f'[旧路径] {rel}: 引用 backup-xiaomeng.ps1 (已移到 scripts/)')
        
        # Check 5: References FUND.md without products/
        if 'FUND.md' in content and 'products/FUND' not in content:
            if str(rel) != 'products/FUND.md' and str(rel) != 'README.md':
                issues.append(f'[旧路径] {rel}: 引用 FUND.md (已移到 products/)')
        
        # Check 6: Obsolete auto-archive references
        if 'auto-archive' in content:
            if str(rel) != 'README.md':  # README might mention it historically
                issues.append(f'[过期] {rel}: 引用已删除的 auto-archive-cron.sh')

print('=' * 60)
print('全仓库文件审查报告')
print('=' * 60)

if not issues:
    print('\n✅ 未发现问题！一切正常')
else:
    # Group by type
    by_type = {}
    for i in issues:
        typ = i.split(']')[0] + ']'
        if typ not in by_type:
            by_type[typ] = []
        by_type[typ].append(i)
    
    for typ, items in sorted(by_type.items()):
        print(f'\n{typ} ({len(items)}处):')
        for item in items:
            print(f'  {item}')

print(f'\n总问题数: {len(issues)}')
