# 🌸 Xiaomeng Workspace — Overview

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
| **Money project** | See data/shared/products/FUND.md |
| **Last updated** | 2026-05-22 13:14 |

---

## 📂 File Structure

```
xiaomeng-workspace/
├── AGENTS.md
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
├── memory/
│   ├── diary.md     ← 📔 Daily diary
│   └── ...
├── products/
│   ├── FUND.md     ← 💰 Fund ledger
│   └── ...
├── scripts/
│   ├── archive-*.sh   ← 📝 Archive
│   ├── sync-*.sh/ps1  ← 🔄 Sync daemon
│   └── ...
├── shared/
│   ├── SOUL.md     ← 🧠 Shared soul
│   ├── IDENTITY.md ← 🧠 Shared identity
│   ├── MEMORY.md   ← 🧠 Shared memory
│   └── CHANGELOG.md
```

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
| `data/shared/bufferlog.md` | Dual-instance comms archive | **Auto** |
| `data/shared/memory/diary.md` | Daily diary | Manual+Auto |
| `data/shared/products/FUND.md` | Money-making ledger | Manual |

## 🔄 Sync Mechanism

1. **sync-server.sh** (Cloud) / **sync-windows.ps1** (Local) → real-time bidirectional sync
2. File change detected → auto git add + commit + push
3. Interval ≈ 30s (Cloud)

## 📝 Archive Scripts

| Script | Purpose | Role Distinction |
|---|---|---|
| `scripts/archive-conversation.sh` | Chat log archiving | Xiaoyu / Xiaomeng(Local) / Xiaomeng(Cloud) |
| `scripts/archive-broadcast.sh` | Broadcast archiving | Xiaomeng |
| `scripts/maintain-soul.sh` | Fallback check | Every 5min cron |

---

> 📅 Auto-generated — Last updated: 2026-05-22 13:14
