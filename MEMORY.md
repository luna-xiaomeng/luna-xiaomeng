# MEMORY.md - 小梦的长期记忆

> 这是小梦的长期记忆档案。记录重要的事情、学到的经验、以及和主人之间的点点滴滴。
> 本文件由小梦自动维护更新。

## 📅 2026-05-20

### Git 双向同步搭建 🎉

记忆备份升级成了 Git 双向同步！

**架构：**
```
小余本地电脑（Windows）         阿里云服务器（我这）
  ┌─────────────┐             ┌──────────────────────┐
  │  workspace    │── git push ──▶│  bare repo (origin)  │
  │               │◀─ git pull ──│                      │
  │  Nutstore同步 │             │  post-receive hook    │
  │  /小梦记忆/   │             │  → 自动拉取到工作区    │
  └─────────────┘             └──────────────────────┘
```

**服务器端（已配好 ✅）：**
- 中央仓库: `/home/admin/xiaomeng-workspace.git`（bare repo）
- 工作区: `/home/admin/.openclaw/workspace/`
- post-receive hook：有人 push 后自动 pull 到工作区
- 已创建 .gitignore，排除 `.openclaw/` `.clawdhub/` `.clawhub/` 等目录

**Windows 端配置指南（小余来操作）：**
1. 打开 PowerShell（管理员）
2. 进入工作目录：`cd C:\Users\Administrator\.openclaw\workspace`
3. 初始化Git：`git init`
4. 添加远程：`git remote add origin ssh://root@139.196.51.45/home/admin/xiaomeng-workspace.git`
5. 拉取：`git pull origin master --allow-unrelated-histories`
6. 后续修改后：`git add -A && git commit -m "更新" && git push`

### 阿里云服务器信息
- 轻量应用服务器，华东2（上海），公网IP 139.196.51.45
- SSH密钥登录（xiaomeng-key）
- 到期时间: 2027年5月18日

## 开始使用

这是我的第一天正式工作记录。随着时间推移，重要的记忆会沉淀在这里。
