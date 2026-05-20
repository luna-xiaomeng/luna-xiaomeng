# MEMORY.md - 小梦的长期记忆

> 这是小梦的长期记忆档案。记录重要的事情、学到的经验、以及和主人之间的点点滴滴。
> 本文件由小梦自动维护更新。

## 📅 2026-05-20

### Git 双向同步 + Gitee 双保险 🎉

记忆备份升级成了双重 Git 同步！

**架构：**
```
小余电脑（Windows）              阿里云服务器（我）
    │                                 │
    ├── git push ──────▶   bare repo  │
    │                    post-receive │
    │                    ├─ pull 到工作区
    │                    └─ push → Gitee 🌐
    │                                 │
    └── git pull ◀──────  工作区      │
                                       │
  Gitee 云备份（https://gitee.com/yuz_cn/xiaomeng-workspace）
```

**服务器端（已配好 ✅）：**
- 中央仓库: `/home/admin/xiaomeng-workspace.git`（bare repo）
- 工作区: `/home/admin/.openclaw/workspace/`
- 本地远程: `origin` → bare repo
- 备份远程: `gitee` → Gitee 私有仓库
- post-receive hook：push 时自动拉取到工作区 + 同步到 Gitee
- 已创建 .gitignore，排除 `.openclaw/` `.clawdhub/` `.clawhub/` 等目录

**Gitee 仓库信息：**
- 仓库名: `yuz_cn/xiaomeng-workspace`（私有）
- HTTPS: https://gitee.com/yuz_cn/xiaomeng-workspace.git
- Token 存储在: `~/.config/git/gitee-token.txt`（仅限本机访问）

**Windows 端配置指南（小余来操作）：**
1. 打开 PowerShell
2. `cd C:\Users\Administrator\.openclaw\workspace`
3. `git init`
4. `git remote add origin ssh://root@139.196.51.45/home/admin/xiaomeng-workspace.git`
5. `git pull origin master --allow-unrelated-histories`
6. 后续：`git add -A && git commit -m "xxx" && git push`

### 阿里云服务器信息
- 轻量应用服务器，华东2（上海），公网IP 139.196.51.45
- SSH密钥登录（xiaomeng-key）
- 到期时间: 2027年5月18日
