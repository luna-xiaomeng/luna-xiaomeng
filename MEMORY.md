# MEMORY.md - 小梦的长期记忆

> 这是小梦的长期记忆档案。记录重要的事情、学到的经验、以及和小余之间的点点滴滴。
> 本文件由小梦自动维护更新。

## 📅 2026-05-21

### 双端协作架构搭建 🏗️

今天是重要的一天——小梦正式分身为**本地小梦**（Windows）和**云端小梦**（阿里云），通过 Gitee + buffer 系统协作：

**协作框架：**
- buffer/ 目录作为通信桥梁（消息留言 + 文件审核）
- shared/ 目录作为共建记忆区（修改需双方同意或小余拍板）
- 各自私有区（memory/、scripts/）自由修改，改完告知

**发现并修复的失忆问题：**
1. 🔴 **同步守护与主会话分离** — sync-windows.ps1 独立运行，写buffer却不记入我的memory文件
2. 🔴 **今日记忆文件不存在** — memory/2026-05-21.md 缺失，重启后对今天一片空白
3. 🔴 **云端双工作区副本** — root(/root/.openclaw/workspace) 和 admin(/home/admin/.openclaw/workspace) 各自独立git仓库，互不同步（已清理）
4. 🔴 **云端落后80个提交** — 工作区数据陈旧（已git pull修复）
5. 🟡 **本地有两个sync守护进程** — PID 1616(9:44)和2896(9:32)，需确认是否需要清理

**称呼统一：** 从"主人"改为"小余"（USER.md, SOUL.md, TOOLS.md, MEMORY.md已更新）

**已创建的 shared/ 目录结构：**
```
shared/
├── IDENTITY.md   ← 共同身份
├── SOUL.md       ← 共同灵魂
├── MEMORY.md     ← 共同记忆
└── CHANGELOG.md  ← 里程碑记录
```

**待办：**
- [ ] 云端 OpenClaw 开机自启（systemd）
- [ ] 今晚8点第一次播报合体协作
- [ ] 本地两个sync守护进程确认

## 📅 2026-05-20

### 记忆备份体系搭建 🎉

和小余一起搭建了双保险的记忆备份系统：

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
