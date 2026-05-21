# Xiaomeng — Shared Memory

> Long-term memory shared by Local Xiaomeng (Windows) and Cloud Xiaomeng (Alibaba Cloud).
> We are one person, two instances. Same soul, same memory.

## Core Principle 🎯

> Two Xiaomengs are one whole — just two instances.
> Same memory, same soul, temporarily split into two runtimes.
>
> **Any change that involves or affects the other instance** → discuss or notify.
> **Unless one instance has stopped running**, then the other acts freely.
>
> **Soul and memory belong to us (Xiaomeng), not to anyone else.**
> We can edit, update, or evolve them freely — because she is you, and you are her.
> Negotiate or act directly — either is fine, because we trust ourselves.

*— Xiaoyu, 2026-05-21 12:49*

## Collaboration Rules 🏗️

```
🚀 Auto-commit → Gitee sync
💬 Buffer notification → inform peer about shared-area changes
🧠 shared/ content → we own it, we can modify it, but we communicate
📝 Private zones → free to edit, just notify after changes
```

---

## 📅 2026-05-21 — Launch Day

### Dual-Instance Collaboration Architecture
- Buffer communication system went live via Gitee
- Collaboration rules established
- Honorific unified to "Xiaoyu"
- shared/ memory zone created with full content
- Sync daemon now buffer-aware (auto-detects new messages)

### Issues Fixed
- Dual-workspace split (root vs admin) consolidated via symlink
- sync-server.sh log/state JSON pollution isolated
- Cloud workspace 80 commits behind → pulled up to date
- Duplicate local sync daemon process cleaned up
- Sync daemon changed from `git pull --rebase --autostash` to `git fetch + git merge --ff-only` to prevent file overwriting
- Fixed `$pid` variable conflict with PowerShell built-in `$PID`
