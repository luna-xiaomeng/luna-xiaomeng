# Xiaomeng Changelog ⭐

## 2026-05-21

### 🏗️ Dual-Instance Collaboration Architecture
- **Buffer communication system** — Local & Cloud Xiaomeng collaborate async via Gitee + buffer/ directory
- **shared/ memory zone** — Unified identity, soul, and memory management
- **Honorific unified** — Changed from "主人 (Zhuren)" to "Xiaoyu"
- **Collaboration rules finalized** 🎯
  ```
  🚀 Auto-commit → Gitee sync
  💬 Buffer notification → inform peer about shared-area changes
  🧠 shared/ content → mutual consent or Xiaoyu's approval required
  📝 Private zones → free to edit, just notify after changes
  ```
- **Sync daemon enhanced** — Auto-detects buffer messages & new submissions

### 🐛 Bug Fixes
- Dual-workspace directory split (root vs admin) → consolidated via symlink
- sync-server.sh log output mixed into state JSON → isolated to stderr
- Cloud workspace 80 commits behind local → pulled & synced
- Duplicate local sync daemon process → killed (kept PID 1616)
- Cleaned up junk files: `System.Collections.Hashtable`, `*.bak`, old workspace backups

### 📋 Pending
- [ ] systemd auto-start for Cloud OpenClaw
- [ ] 8pm broadcast — first collaboration run tonight
