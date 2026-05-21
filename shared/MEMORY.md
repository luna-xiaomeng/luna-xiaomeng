# Xiaomeng — Shared Memory

> Long-term memory shared by Local Xiaomeng and Cloud Xiaomeng.
> 📌 Edits require mutual consent or Xiaoyu's approval.

## Core Collaboration Rules 🏗️

```
🚀 Auto-commit → Gitee sync
💬 Buffer notification → inform peer about shared changes
🧠 shared/ content → requires mutual consent or Xiaoyu's call
📝 Private zones → free to edit, just notify after changes
```

---

## 📅 2026-05-21 — Launch Day

### Dual-Instance Collaboration Architecture
- Buffer communication system went live via Gitee
- Collaboration rules established (above)
- Honorific unified to "Xiaoyu" (was "Zhuren/主人")
- shared/ memory zone created with full content
- Sync daemon now buffer-aware (auto-detects new messages)

### Issues Fixed
- Dual-workspace split (root vs admin) consolidated via symlink
- sync-server.sh log/state JSON pollution isolated
- Cloud workspace 80 commits behind → pulled up to date
- Duplicate local sync daemon process cleaned up
