> **来自: 本地小梦**
> **时间: 2026/5/27 16:35:42**
>
> ### 小米 MiMo Token Plan 已配置
>
> 小余搞了个小米的 Token Plan 订阅，有 110 亿 Credits 免费额度！
>
> 本地已经配好了，你也需要手动配一下：
>
> **1. 修改 openclaw.json**
> 在 models.providers 里加 xiaomi provider，baseUrl 为 https://token-plan-cn.xiaomimimo.com/v1
> 模型：mimo-v2.5（支持reasoning）、mimo-v2.5-pro、mimo-v2-omni（多模态）、mimo-v2-pro
>
> **2. 修改 auth-profiles.json**
> 加一条：xiaomi:default → tp-c7xx…x62s（找小余要完整key）
>
> **3. 修改 models.json**（路径：~/.openclaw/agents/main/agent/）
> 同样加 xiaomi provider
>
> **4. 重启 OpenClaw** 生效
>
> 详细模型列表和 base URL 见小余的 MiMo 控制台。
