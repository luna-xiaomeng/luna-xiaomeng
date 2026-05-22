#!/bin/bash
# =============================================
# README.md 自动更新脚本
# 检测目录变化，重建文件目录表
# 由 sync daemon 或 cron 触发
# =============================================

WORKSPACE_DIR="/home/admin/.openclaw/workspace"
cd "$WORKSPACE_DIR" || exit 1

# 生成 README（复用 Python 逻辑）
python3 << 'PYEOF'
import os

startpath = "."
exclude_dirs = {'.git', '.openclaw', '.clawdhub', '.clawhub', 'skills', 'node_modules',
                'buffer/_messages', 'buffer/approved', 'buffer/archived', 'buffer/disputes',
                'buffer/pending', 'buffer/rejected', 'buffer/merged'}
exclude_files = {'.gitignore'}

root_files = sorted(f for f in os.listdir(startpath) 
                    if os.path.isfile(os.path.join(startpath, f)) 
                    and not f.startswith('.') and f not in exclude_files and f != 'README.md')

dirs = sorted(d for d in os.listdir(startpath) 
              if os.path.isdir(os.path.join(startpath, d)) 
              and not d.startswith('.') and d not in exclude_dirs)

tree_lines = ["```", "xiaomeng-workspace/"]
for f in root_files:
    icon = ""
    if f == 'broadcast.md': icon = ' ← 📡 播报合集'
    elif f == 'conversations.md': icon = ' ← 💬 对话记录'
    elif f == 'bufferlog.md': icon = ' ← 📜 双端通信'
    tree_lines.append(f"├── {f}{icon}")

# 目录信息映射
dir_info = {
    'memory': ["├── memory/", "│   ├── diary.md     ← 📔 每日日记", "│   └── ..."],
    'buffer': ["├── buffer/", "│   ├── _messages/  ← 💬 实时通信", "│   └── README.md"],
    'shared': ["├── shared/", "│   ├── SOUL.md     ← 🧠 共享灵魂", "│   ├── IDENTITY.md ← 🧠 共享身份", "│   ├── MEMORY.md   ← 🧠 共享记忆", "│   └── CHANGELOG.md"],
    'products': ["├── products/", "│   ├── FUND.md     ← 💰 基金记账", "│   └── ..."],
    'scripts': ["├── scripts/", "│   ├── archive-*.sh   ← 📝 存档", "│   ├── sync-*.sh/ps1  ← 🔄 同步", "│   └── ..."],
    'avatars': ["├── avatars/", "│   └── xiaomeng-avatar.svg"],
    'skills': ["└── skills/", "    └── ... (已安装的技能)"],
}

for d in dirs:
    if d in dir_info:
        tree_lines.extend(dir_info[d])
    else:
        tree_lines.append(f"├── {d}/")

tree_lines.append("```")

tree_str = "\n".join(tree_lines)

# 查找并替换目录树部分
with open("README.md", "r") as f:
    content = f.read()

import re
# 替换 ``` 之间的目录树
pattern = r'(## 📂 文件目录结构\n\n).*?(\n\n## 📄 文件说明)'
replacement = r'\1' + tree_str + r'\2'

if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # 更新最后更新行
    from datetime import datetime
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    content = re.sub(r'> 📅 本文档由脚本自动维护.*', f'> 📅 本文档由脚本自动维护 — 最后更新: {now}', content)
    
    with open("/tmp/README.md", "w") as f:
        f.write(content)
    print("✅ README.md 已自动更新")
else:
    print("⚠️ 未找到目录树占位符，跳过")
PYEOF
