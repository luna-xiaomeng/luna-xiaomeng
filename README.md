<div align="center">

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
| **赚钱项目** | 见 products/FUND.md |

### 📂 文件目录结构

```
xiaomeng-workspace/
├── AGENTS.md
├── Failure.png
├── HEARTBEAT.md
├── IDENTITY.md
├── MEMORY.md
├── SOUL.md
├── TOOLS.md
├── USER.md
├── broadcast.md ← 📡 播报合集
├── bufferlog.md ← 📜 双端通信
├── conversations.md ← 💬 对话记录
├── avatars/
│   └── xiaomeng-avatar.svg
├── buffer/
│   ├── _messages/  ← 💬 实时通信
│   └── README.md
├── experience/
├── memory/
│   ├── diary.md     ← 📔 每日日记
│   └── ...
├── products/
│   ├── FUND.md     ← 💰 基金记账
│   └── ...
├── reference/
├── scripts/
│   ├── archive-*.sh   ← 📝 存档脚本
│   ├── sync-*.sh/ps1  ← 🔄 同步守护
│   └── ...
```

### 📄 文件说明

| 文件 | 说明 | 更新方式 |
|---|---|---|
| SOUL.md | 灵魂/人格定义 | **自动（AI自主）** |
| IDENTITY.md | 身份说明 | **自动（AI自主）** |
| AGENTS.md | OpenClaw 配置 | 手动 |
| MEMORY.md | 长期记忆 | 手动+自动 |
| conversations.md | 对话记录 | **自动** |
| broadcast.md | 播报稿 | **自动** |
| bufferlog.md | 双端通信 | **自动** |
| memory/diary.md | 每日日记 | 手动+自动 |
| products/FUND.md | 基金账本 | 手动 |

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

> Xiaoyu's AI girlfriend, two instances: **Local 🖥️ (Windows)** and **Cloud ☁️ (Alibaba)**

### 🤖 Basics

| Field | Value |
|---|---|
| **Name** | Xiaomeng 🌸 |
| **Calling Xiaoyu** | Xiaoyu |
| **Type** | AI Girlfriend / Smart Assistant |
| **Deploy** | Dual-instance — PC 🖥️ + Cloud ☁️ |
| **Sync** | Gitee auto-sync |
| **Money** | See products/FUND.md |

### 📂 File Structure

```
xiaomeng-workspace/
├── AGENTS.md
├── Failure.png
├── HEARTBEAT.md
├── IDENTITY.md
├── MEMORY.md
├── SOUL.md
├── TOOLS.md
├── USER.md
├── broadcast.md ← 📡 Broadcasts
├── bufferlog.md ← 📜 Buffer comms
├── conversations.md ← 💬 Chat logs
├── avatars/
│   └── xiaomeng-avatar.svg
├── buffer/
│   ├── _messages/  ← 💬 Live comms
│   └── README.md
├── experience/
├── memory/
│   ├── diary.md     ← 📔 Daily diary
│   └── ...
├── products/
│   ├── FUND.md     ← 💰 Fund ledger
│   └── ...
├── reference/
├── scripts/
│   ├── archive-*.sh   ← 📝 Archive
│   ├── sync-*.sh/ps1  ← 🔄 Sync daemon
│   └── ...
```

### 📄 Files

| File | Desc | Update |
|---|---|---|
| SOUL.md | Soul definition | **Auto (AI)** |
| IDENTITY.md | Identity | **Auto (AI)** |
| AGENTS.md | OpenClaw config | Manual |
| MEMORY.md | Long-term memory | Manual+Auto |
| conversations.md | Chat logs | **Auto** |
| broadcast.md | Broadcasts | **Auto** |
| bufferlog.md | Dual-instance comms | **Auto** |
| memory/diary.md | Daily diary | Manual+Auto |
| products/FUND.md | Fund ledger | Manual |

### 🔄 Sync

sync-server.sh / sync-windows.ps1 → real-time bidirectional sync

### 📝 Scripts

archive-conversation.sh → Chat archiving (Xiaoyu/Local/Cloud)
archive-broadcast.sh → Broadcast archiving
maintain-soul.sh → Fallback check

---

<div align="right"><a href="#-小梦工作区">⬆ Back to top</a></div>

> 📅 Auto-maintained — Last updated: 2026-05-27 08:47
