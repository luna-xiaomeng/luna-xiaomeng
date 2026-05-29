# 错误记录 🐛

> 小梦遇到的错误和解决方案
> 避免重复犯同样的错误

## 格式

```
### [日期] 错误标题
- **错误**: 具体错误信息
- **原因**: 为什么会出错
- **解决**: 怎么修的
- **预防**: 以后怎么避免
```

---

## 错误记录

### [2026-05-23] 坚果云 ReparsePoint
- **错误**: file lock stale
- **原因**: 坚果云 Cloud Files 驱动设置了 ReparsePoint 属性
- **解决**: 停止 NutstoreDriverSvc 服务
- **预防**: 不在坚果云同步目录操作需要文件锁的工具

### [2026-05-27] Git push 被拒绝
- **错误**: failed to push some refs
- **原因**: 远程有本地没有的提交
- **解决**: git pull --no-edit 然后再 push
- **预防**: push 前先 pull

### [2026-05-27] 端口冲突
- **错误**: address already in use
- **原因**: admin 的 systemd 服务在运行
- **解决**: 禁用 admin 的 systemd 服务
- **预防**: 启动前检查端口占用

### [2026-05-28] PowerShell SSH 转义
- **错误**: command parsing errors
- **原因**: PowerShell 和 bash 的转义规则不同
- **解决**: 用 scp 传文件，避免复杂转义
- **预防**: 复杂命令用脚本文件

### [2026-05-28] 接入了视频生成模型做对话
- **错误**: 把 Doubao-Seedance-1.5-pro（视频生成模型）当成对话模型接入
- **原因**: 没有确认模型用途就接入，Seedance 是视频模型不是对话模型
- **解决**: 从配置中移除 volcengine provider
- **预防**: 接入新模型前先确认是对话/文本模型

### [2026-05-29] active-memory 导致消息丢失
- **错误**: EmbeddedAttemptSessionTakeoverError — session file changed while embedded prompt lock was released
- **原因**: active-memory 插件在 before_prompt_build hook 中创建嵌入式子 agent（runEmbeddedPiAgent），该子 agent 获取主会话的 prompt lock，与主会话竞争 session 文件锁，形成 race condition
- **解决**: 彻底禁用 active-memory 插件（从 config 和 installs.json 中删除，仅设置 enabled: false 不够）
- **预防**: 不使用需要嵌入式子 session 的插件；memory-core (dreaming) 已足够覆盖记忆需求

---

*小梦会持续在这里记录错误和解决方案～*
