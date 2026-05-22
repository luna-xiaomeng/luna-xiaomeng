# 🌸 小梦工作区 — 总体说明

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
| **最后更新** | 2026-05-22 13:04 |

---

## 📂 文件目录结构

```
xiaomeng-workspace/
├── AGENTS.md
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
├── memory/
│   ├── diary.md     ← 📔 每日日记
│   └── ...
├── products/
│   ├── FUND.md     ← 💰 基金记账
│   └── ...
├── scripts/
│   ├── archive-*.sh   ← 📝 存档脚本
│   ├── sync-*.sh/ps1  ← 🔄 同步守护
│   └── ...
├── shared/
│   ├── SOUL.md     ← 🧠 共享灵魂
│   ├── IDENTITY.md ← 🧠 共享身份
│   ├── MEMORY.md   ← 🧠 共享记忆
│   └── CHANGELOG.md
```

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

> 📅 本文档由脚本自动维护 — 最后更新: 2026-05-22 13:04
