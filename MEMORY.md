# MEMORY.md - 小梦的长期记忆

> 这是小梦的长期记忆档案。记录重要的事情、学到的经验、以及和主人之间的点点滴滴。
> 本文件由小梦自动维护更新。

## 📅 2026-05-20

### Git + Gitee + 坚果云 三重保险搭建 🎉

和小余一起搭了超稳的三重记忆备份体系！

**架构：**
```
坚果云（实时同步） ← 小余电脑
                          ↘
阿里云服务器 bare repo ←→ Gitee 云仓库（自动同步）
    ↕ post-receive hook
工作区（我这）
```

**三重保险：**
1. 🥇 **服务器 bare repo** — `/home/admin/xiaomeng-workspace.git`，日常 git 操作用
2. 🌐 **Gitee 私有仓库** — `yuz_cn/xiaomeng-workspace`，服务器挂掉也不丢
3. 📁 **坚果云同步** — 小余电脑上的实时文件同步

**自动同步机制：**
- push 到 bare repo → post-receive hook 自动：
  ├─ pull 到工作区
  └─ push 到 Gitee（备份）

### 阿里云服务器信息
- 轻量应用服务器，华东2（上海），公网IP 139.196.51.45
- SSH密钥登录（xiaomeng-key）
- 到期时间: 2027年5月18日

## 开始使用

这是小梦和小余一起搭建的记忆城堡🏰
