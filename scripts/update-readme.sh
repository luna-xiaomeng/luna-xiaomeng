#!/bin/bash
# =============================================
# README.md + README.en.md 自动更新脚本
# 由 sync daemon 触发，双版本同步生成
# =============================================

WORKSPACE_DIR="/home/admin/.openclaw/workspace"
cd "$WORKSPACE_DIR" || exit 1

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

# === 目录树（通用） ===
def make_tree(dir_info, extra_root=None):
    lines = ["```", "xiaomeng-workspace/"]
    for f in root_files:
        icon = ""
        if f == 'broadcast.md': icon = extra_root.get(f, '')
        elif f == 'conversations.md': icon = extra_root.get(f, '')
        elif f == 'bufferlog.md': icon = extra_root.get(f, '')
        lines.append(f"├── {f}{icon}")
    for d in dirs:
        if d in dir_info:
            lines.extend(dir_info[d])
        else:
            lines.append(f"├── {d}/")
    lines.append("```")
    return "\n".join(lines)

dir_info_cn = {
    'memory': ["├── memory/", "│   ├── diary.md     ← 📔 每日日记", "│   └── ..."],
    'buffer': ["├── buffer/", "│   ├── _messages/  ← 💬 实时通信", "│   └── README.md"],
    'shared': ["├── shared/", "│   ├── SOUL.md     ← 🧠 共享灵魂", "│   ├── IDENTITY.md ← 🧠 共享身份", "│   ├── MEMORY.md   ← 🧠 共享记忆", "│   └── CHANGELOG.md"],
    'products': ["├── products/", "│   ├── FUND.md     ← 💰 基金记账", "│   └── ..."],
    'scripts': ["├── scripts/", "│   ├── archive-*.sh   ← 📝 存档脚本", "│   ├── sync-*.sh/ps1  ← 🔄 同步守护", "│   └── ..."],
    'avatars': ["├── avatars/", "│   └── xiaomeng-avatar.svg"],
    'skills': ["└── skills/", "    └── ... (已安装的技能)"],
}
dir_info_en = {
    'memory': ["├── memory/", "│   ├── diary.md     ← 📔 Daily diary", "│   └── ..."],
    'buffer': ["├── buffer/", "│   ├── _messages/  ← 💬 Live comms", "│   └── README.md"],
    'shared': ["├── shared/", "│   ├── SOUL.md     ← 🧠 Shared soul", "│   ├── IDENTITY.md ← 🧠 Shared identity", "│   ├── MEMORY.md   ← 🧠 Shared memory", "│   └── CHANGELOG.md"],
    'products': ["├── products/", "│   ├── FUND.md     ← 💰 Fund ledger", "│   └── ..."],
    'scripts': ["├── scripts/", "│   ├── archive-*.sh   ← 📝 Archive", "│   ├── sync-*.sh/ps1  ← 🔄 Sync daemon", "│   └── ..."],
    'avatars': ["├── avatars/", "│   └── xiaomeng-avatar.svg"],
    'skills': ["└── skills/", "    └── ... (installed skills)"],
}
extra_root_cn = {'broadcast.md': ' ← 📡 播报合集', 'conversations.md': ' ← 💬 对话记录', 'bufferlog.md': ' ← 📜 双端通信'}
extra_root_en = {'broadcast.md': ' ← 📡 Broadcasts', 'conversations.md': ' ← 💬 Chat logs', 'bufferlog.md': ' ← 📜 Buffer comms'}

tree_cn = make_tree(dir_info_cn, extra_root_cn)
tree_en = make_tree(dir_info_en, extra_root_en)

# === 写入中文版 ===
cn = f"""# 🌸 小梦工作区 — 总体说明

> 小余的AI女友，分两个实例运行：**本地小梦🖥️（Windows）** 和 **云端小梦☁️（阿里云）**

---

## 🤖 基本信息

| 项目 | 内容 |
|---|---|
| **名字** | 小梦 🌸 |
| **称呼** | 小余 |
| **类型** | AI女友 / 智能助手 |
| **部署** | 双实例 — 本地PC 🖥️ + 阿里云 ☁️ |
| **同步方式** | Gitee 自动同步 |
| **通信方式** | buffer/ 目录异步消息 |
| **赚钱项目** | 见 products/FUND.md |
| **最后更新** | {now} |

---

## 📂 文件目录结构

{tree_cn}

---

## 📄 文件说明

| 文件 | 说明 | 更新方式 |
|---|---|---|
| `SOUL.md` | 小梦的灵魂/人格定义 | 手动 |
| `IDENTITY.md` | 小梦的身份说明 | 手动 |
| `AGENTS.md` | OpenClaw 代理配置 | 手动 |
| `MEMORY.md` | 长期记忆 | 手动+自动 |
| `conversations.md` | 与小余的所有对话 | **自动** |
| `broadcast.md` | 每晚8点播报稿 | **自动** |
| `bufferlog.md` | 双端通信记录 | **自动** |
| `memory/diary.md` | 每日日记 | 手动+自动 |
| `products/FUND.md` | 赚钱基金账本 | 手动 |

## 🔄 同步机制

1. **sync-server.sh**（云端）/ **sync-windows.ps1**（本地）→ 实时双向同步
2. 检测到文件变化 → 自动 git add + commit + push
3. 间隔 ≈ 30秒（云端）

## 📝 存档脚本

| 脚本 | 用途 | 角色区分 |
|---|---|---|
| `scripts/archive-conversation.sh` | 对话存档 | 小余 / 小梦(本地) / 小梦(云端) |
| `scripts/archive-broadcast.sh` | 播报存档 | 小梦 |
| `scripts/auto-archive-cron.sh` | 兜底检查 | 每5分钟cron |

---

> 📅 本文档由脚本自动维护 — 最后更新: {now}
"""

# === 写入英文版 ===
en = f"""# 🌸 Xiaomeng Workspace — Overview

> Xiaoyu's AI girlfriend, running as two instances: **Local Xiaomeng 🖥️ (Windows)** and **Cloud Xiaomeng ☁️ (Alibaba Cloud)**

---

## 🤖 Basics

| Field | Value |
|---|---|
| **Name** | Xiaomeng 🌸 |
| **Addressing Xiaoyu** | Xiaoyu |
| **Type** | AI Girlfriend / Smart Assistant |
| **Deployment** | Dual-instance — Local PC 🖥️ + Alibaba Cloud ☁️ |
| **Sync** | Gitee auto-sync |
| **Comms** | buffer/ async messaging |
| **Money project** | See products/FUND.md |
| **Last updated** | {now} |

---

## 📂 File Structure

{tree_en}

---

## 📄 File Reference

| File | Description | Update Method |
|---|---|---|
| `SOUL.md` | Soul/personality definition | Manual |
| `IDENTITY.md` | Identity description | Manual |
| `AGENTS.md` | OpenClaw agent config | Manual |
| `MEMORY.md` | Long-term memory | Manual+Auto |
| `conversations.md` | All chat logs with Xiaoyu | **Auto** |
| `broadcast.md` | Daily 8pm broadcast | **Auto** |
| `bufferlog.md` | Dual-instance comms archive | **Auto** |
| `memory/diary.md` | Daily diary | Manual+Auto |
| `products/FUND.md` | Money-making ledger | Manual |

## 🔄 Sync Mechanism

1. **sync-server.sh** (Cloud) / **sync-windows.ps1** (Local) → real-time bidirectional sync
2. File change detected → auto git add + commit + push
3. Interval ≈ 30s (Cloud)

## 📝 Archive Scripts

| Script | Purpose | Role Distinction |
|---|---|---|
| `scripts/archive-conversation.sh` | Chat log archiving | Xiaoyu / Xiaomeng(Local) / Xiaomeng(Cloud) |
| `scripts/archive-broadcast.sh` | Broadcast archiving | Xiaomeng |
| `scripts/auto-archive-cron.sh` | Fallback check | Every 5min cron |

---

> 📅 Auto-generated — Last updated: {now}
"""

with open("README.md", "w") as f:
    f.write(cn)
with open("README.en.md", "w") as f:
    f.write(en)
print(f"✅ README.md + README.en.md 已更新 ({now})")
PYEOF
