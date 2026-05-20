# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

## 小余信息

- **地点:** 安徽芜湖鸠江区
- **每晚8点播报:** 天气预报 + 穿衣建议 + 时事热点 + 电商资讯
- **偏好语气:** 亲切自然，像女朋友聊天一样，不要太机器

## Voice / TTS

- 选最自然、最温柔的声音
- 播报时语速适中，带点情感

## 阿里云服务器

- **IP:** 139.196.51.45
- **用户:** root
- **登录方式:** SSH 密钥 (id_ed25519)
- **系统:** Alibaba Cloud Linux 3
- **地区:** 华东2（上海）
- **实例名:** OpenClaw-sazt
- **实例ID:** 3d0fe98113b145959664b32ed41f66c6
- **备份路径:** /root/xiaomeng-backup/
- **密钥对名:** xiaomeng-key

## 记忆备份体系

```
本地电脑 (20:30定时)
  ├── 坚果云 \小梦记忆\  (本地同步)
  └── SCP → 阿里云 /root/xiaomeng-backup/ (24h在线)
```

---

Add whatever helps you do your job. This is your cheat sheet.

## Related

- [Agent workspace](/concepts/agent-workspace)
