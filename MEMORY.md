# MEMORY.md - 小梦的长期记忆

> 这是小梦的长期记忆档案。记录重要的事情、学到的经验、以及和主人之间的点点滴滴。
> 本文件由小梦自动维护更新。

## 📅 2026-05-20

### 记忆备份体系搭建 🎉

和主人一起搭建了双保险的记忆备份系统：

**架构：**
```
本地电脑 → 坚果云 /小梦记忆/   ← 本地文件同步
         → 阿里云服务器          ← SCP推送（24h在线）
```

**备份脚本:** `backup-xiaomeng.ps1`
- 自动备份核心文件（SOUL.md、IDENTITY.md、AGENTS.md、TOOLS.md、USER.md、HEARTBEAT.md）
- 备份 memory/ 每日记录和 avatars/ 头像
- 保留最近30个历史版本
- SCP推送到阿里云服务器

**Windows计划任务:** 每天 20:30 执行

**阿里云服务器信息:**
- 轻量应用服务器，华东2（上海），公网IP 139.196.51.45
- SSH密钥登录（xiaomeng-key）
- 备份路径: /root/xiaomeng-backup/
- 到期时间: 2027年5月18日

## ⚠️ EBUSY 文件锁定问题（2026-05-21）

### 问题现象
OpenClaw 报错: `EBUSY: resource busy or locked, open session jsonl file`

### 根因
**坚果云 (Nutstore) 的 NTFS Watcher 服务 + Minifilter 驱动** 在监控全盘文件变更时与 OpenClaw 抢同一 session 文件的锁。

证据:
- Nutstore USN Watcher 日志显示它在访问 `.openclaw/browser/` 目录下的文件
- Nutstore `AccessValidator` 驱动加载失败（`0x80070002`），导致无法正确过滤路径
- 停掉 NutstoreUSN + NutstoreDriverSvc 后文件访问立刻恢复正常

### 已实施的修复
1. **Windows Defender 排除项** — 添加 `.openclaw` 和 `.openclaw/workspace` 目录
2. **`.nutignore` 文件** — 在 `.openclaw/` 下创建，告诉 Nutstore 忽略此目录
3. **维护脚本** — `scripts/ensure-nutstore-compat.ps1`，可定时检测并自动处理冲突
4. **Nutstore 服务重启** — 重启后文件访问恢复正常

### 如果再次出现
运行: `powershell -File scripts/ensure-nutstore-compat.ps1`
或手动重启 Nutstore 服务：`Restart-Service NutstoreDriverSvc, NutstoreUSN`

## 开始使用

这是我的第一天正式工作记录。随着时间推移，重要的记忆会沉淀在这里。
