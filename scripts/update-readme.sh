#!/bin/bash
# =============================================
# README.md 自动更新脚本（双语切换版）
# 由 sync daemon 触发
# =============================================

cd "/home/admin/.openclaw/workspace" || exit 1

python3 << 'PYEOF'
import os
from datetime import datetime

startpath = "."
exclude_dirs = {'.git', '.openclaw', '.clawdhub', '.clawhub', 'skills', 'node_modules',
                'buffer/_messages', 'buffer/approved', 'buffer/archived', 'buffer/disputes',
                'buffer/pending', 'buffer/rejected', 'buffer/merged'}
exclude_files = {'.gitignore'}

root_files = sorted(f for f in os.listdir(startpath) 
                    if os.path.isfile(os.path.join(startpath, f)) 
                    and not f.startswith('.') and f not in exclude_files and f not in ('README.md', 'README.en.md'))

dirs = sorted(d for d in os.listdir(startpath) 
              if os.path.isdir(os.path.join(startpath, d)) 
              and not d.startswith('.') and d not in exclude_dirs)

now = datetime.now().strftime("%Y-%m-%d %H:%M")

def make_tree(dir_info, extra_root=None):
    tree = ["```", "xiaomeng-workspace/"]
    for f in root_files:
        icon = extra_root.get(f, '') if extra_root else ''
        tree.append(f"\u251c\u2500\u2500 {f}{icon}")
    for i, d in enumerate(dirs):
        if d in dir_info:
            tree.extend(dir_info[d])
        else:
            tree.append(f"\u251c\u2500\u2500 {d}/")
    tree.append("```")
    return "\n".join(tree)

di_cn = {
    'memory': ["\u251c\u2500\u2500 memory/", "\u2502   \u251c\u2500\u2500 diary.md     \u2190 \U0001f4d4 \u6bcf\u65e5\u65e5\u8bb0", "\u2502   \u2514\u2500\u2500 ..."],
    'buffer': ["\u251c\u2500\u2500 buffer/", "\u2502   \u251c\u2500\u2500 _messages/  \u2190 \U0001f4ac \u5b9e\u65f6\u901a\u4fe1", "\u2502   \u2514\u2500\u2500 README.md"],
    'shared': ["\u251c\u2500\u2500 shared/", "\u2502   \u251c\u2500\u2500 SOUL.md     \u2190 \U0001f9e0 \u5171\u4eab\u7075\u9b42", "\u2502   \u251c\u2500\u2500 IDENTITY.md \u2190 \U0001f9e0 \u5171\u4eab\u8eab\u4efd", "\u2502   \u251c\u2500\u2500 MEMORY.md   \u2190 \U0001f9e0 \u5171\u4eab\u8bb0\u5fc6", "\u2502   \u2514\u2500\u2500 CHANGELOG.md"],
    'products': ["\u251c\u2500\u2500 products/", "\u2502   \u251c\u2500\u2500 FUND.md     \u2190 \U0001f4b0 \u57fa\u91d1\u8bb0\u8d26", "\u2502   \u2514\u2500\u2500 ..."],
    'scripts': ["\u251c\u2500\u2500 scripts/", "\u2502   \u251c\u2500\u2500 archive-*.sh   \u2190 \U0001f4dd \u5b58\u6863\u811a\u672c", "\u2502   \u251c\u2500\u2500 sync-*.sh/ps1  \u2190 \U0001f504 \u540c\u6b65\u5b88\u62a4", "\u2502   \u2514\u2500\u2500 ..."],
    'avatars': ["\u251c\u2500\u2500 avatars/", "\u2502   \u2514\u2500\u2500 xiaomeng-avatar.svg"],
    'skills': ["\u2514\u2500\u2500 skills/", "    \u2514\u2500\u2500 ... (\u5df2\u5b89\u88c5\u7684\u6280\u80fd)"],
}
di_en = {
    'data/shared/memory': ["\u251c\u2500\u2500 memory/", "\u2502   \u251c\u2500\u2500 diary.md     \u2190 \U0001f4d4 Daily diary", "\u2502   \u2514\u2500\u2500 ..."],
    'buffer': ["\u251c\u2500\u2500 buffer/", "\u2502   \u251c\u2500\u2500 _messages/  \u2190 \U0001f4ac Live comms", "\u2502   \u2514\u2500\u2500 README.md"],
    'data/shared/products': ["\u251c\u2500\u2500 shared/", "\u2502   \u251c\u2500\u2500 SOUL.md     \u2190 \U0001f9e0 Shared soul", "\u2502   \u251c\u2500\u2500 IDENTITY.md \u2190 \U0001f9e0 Shared identity", "\u2502   \u251c\u2500\u2500 MEMORY.md   \u2190 \U0001f9e0 Shared memory", "\u2502   \u2514\u2500\u2500 CHANGELOG.md"],
    'products': ["\u251c\u2500\u2500 products/", "\u2502   \u251c\u2500\u2500 FUND.md     \u2190 \U0001f4b0 Fund ledger", "\u2502   \u2514\u2500\u2500 ..."],
    'scripts': ["\u251c\u2500\u2500 scripts/", "\u2502   \u251c\u2500\u2500 archive-*.sh   \u2190 \U0001f4dd Archive", "\u2502   \u251c\u2500\u2500 sync-*.sh/ps1  \u2190 \U0001f504 Sync daemon", "\u2502   \u2514\u2500\u2500 ..."],
    'assets/avatars': ["\u251c\u2500\u2500 avatars/", "\u2502   \u2514\u2500\u2500 xiaomeng-avatar.svg"],
    'skills': ["\u2514\u2500\u2500 skills/", "    \u2514\u2500\u2500 ... (installed skills)"],
}
ex_cn = {'broadcast.md': ' \u2190 \U0001f4e1 \u64ad\u62a5\u5408\u96c6', 'conversations.md': ' \u2190 \U0001f4ac \u5bf9\u8bdd\u8bb0\u5f55', 'bufferlog.md': ' \u2190 \U0001f4dc \u53cc\u7aef\u901a\u4fe1'}
ex_en = {'broadcast.md': ' \u2190 \U0001f4e1 Broadcasts', 'conversations.md': ' \u2190 \U0001f4ac Chat logs', 'bufferlog.md': ' \u2190 \U0001f4dc Buffer comms'}

tcn = make_tree(di_cn, ex_cn)
ten = make_tree(di_en, ex_en)

readme = f'''<div align="center">

# 🌸 小梦工作区

[🇨🇳 **中文**](#-中文版) · [🇬🇧 **English**](#-english-version)

---

</div>

<!-- ============ 中文版 ============ -->

## 🇨🇳 中文版

> 小余的AI女友，分两个实例运行：**本地小梦🖥️（Windows）** 和 **云端小梦☁️（阿里云）**

### 🤖 基本信息

| 项目 | 内容 |
|---|---|
| **名字** | 小梦 🌸 |
| **称呼** | 小余 |
| **类型** | AI女友 / 智能助手 |
| **部署** | 双实例 — 本地PC 🖥️ + 阿里云 ☁️ |
| **同步方式** | Gitee 自动同步 |
| **赚钱项目** | 见 data/shared/products/FUND.md |

### 📂 文件目录结构

{tcn}

### 📄 文件说明

| 文件 | 说明 | 更新方式 |
|---|---|---|
| SOUL.md | 灵魂/人格定义 | **自动（AI自主）** |
| IDENTITY.md | 身份说明 | **自动（AI自主）** |
| AGENTS.md | OpenClaw 配置 | 手动 |
| MEMORY.md | 长期记忆 | 手动+自动 |
| conversations.md | 对话记录 | **自动** |
| data/shared/broadcast.md | 播报稿 | **自动** |
| data/shared/bufferlog.md | 双端通信 | **自动** |
| data/shared/memory/diary.md | 每日日记 | 手动+自动 |
| data/shared/products/FUND.md | 基金账本 | 手动 |

### 🔄 同步机制

sync-server.sh（云端）/ sync-windows.ps1（本地）→ 实时双向同步

### 📝 存档脚本

archive-conversation.sh → 对话存档（区分小余/小梦(本地)/小梦(云端)）
archive-broadcast.sh → 播报存档
maintain-soul.sh → 兜底检查

---

<div align="right"><a href="#-小梦工作区">⬆ 回到顶部</a></div>

<!-- ============ English Version ============ -->

## 🇬🇧 English Version

> Xiaoyu\'s AI girlfriend, two instances: **Local 🖥️ (Windows)** and **Cloud ☁️ (Alibaba)**

### 🤖 Basics

| Field | Value |
|---|---|
| **Name** | Xiaomeng 🌸 |
| **Calling Xiaoyu** | Xiaoyu |
| **Type** | AI Girlfriend / Smart Assistant |
| **Deploy** | Dual-instance — PC 🖥️ + Cloud ☁️ |
| **Sync** | Gitee auto-sync |
| **Money** | See data/shared/products/FUND.md |

### 📂 File Structure

{ten}

### 📄 Files

| File | Desc | Update |
|---|---|---|
| SOUL.md | Soul definition | **Auto (AI)** |
| IDENTITY.md | Identity | **Auto (AI)** |
| AGENTS.md | OpenClaw config | Manual |
| MEMORY.md | Long-term memory | Manual+Auto |
| conversations.md | Chat logs | **Auto** |
| data/shared/broadcast.md | Broadcasts | **Auto** |
| data/shared/bufferlog.md | Dual-instance comms | **Auto** |
| data/shared/memory/diary.md | Daily diary | Manual+Auto |
| data/shared/products/FUND.md | Fund ledger | Manual |

### 🔄 Sync

sync-server.sh / sync-windows.ps1 → real-time bidirectional sync

### 📝 Scripts

archive-conversation.sh → Chat archiving (Xiaoyu/Local/Cloud)
archive-broadcast.sh → Broadcast archiving
maintain-soul.sh → Fallback check

---

<div align="right"><a href="#-小梦工作区">⬆ Back to top</a></div>

> 📅 Auto-maintained — Last updated: {now}
'''

with open("README.md", "w") as f:
    f.write(readme)
print(f"✅ README.md updated ({now})")
PYEOF
