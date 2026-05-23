# ClawCode 学习笔记 📚

> 学习时间：2026-05-23 19:19 ~（持续更新）

## 项目概览

- **GitHub:** `github.com/deepelementlab/clawcode`
- **团队：** DeepElementLab（原 instructkr/claw-code 改名而来）
- **本质：** Claude Code 的**干净室重写（Clean-room）**开源版 → 现已发展为独立的 AI 编程代理平台
- **起因：** 2026.3.31 Claude Code 51万行 TypeScript 源码意外泄露，韩国开发者 Sigrid Jin（instructkr）从零重写
- **战绩：** 2小时破5万星 → 24小时超10万星 → **167.4K+ ⭐**，GitHub 史上增速第一
- **名字含义：** "Craftsman's claw" — 工匠之爪
- **许可证：** GPL-3.0

## 设计哲学（四原则）

1. **执行 > 建议** — AI 应该动手做事
2. **编排 > 独白** — 多角色协作 > 单Agent
3. **学习 > 无状态** — 三层经验模型：Instinct → ECAP → TECAP
4. **平台 > 锁定** — 不绑定模型厂商

## 记忆系统（小余说七层）

**官方三层经验模型：**
1. **Instinct（本能）** — 从观察中提取的可复用规则
2. **ECAP（经验胶囊）** — Experience Capsule，带上下文和结果的结构化知识
3. **TECAP（团队经验胶囊）** — Team ECAP，跨角色协作经验

**四种经验维度：** model_experience / agent_experience / skill_experience / team_experience

**可能完整的七层（小余提示）：** 短期会话记忆 → 项目记忆 → 用户偏好 → Instinct → ECAP → Skill → TECAP

## 核心功能

### 终端原生 Agent
- `clawcode` TUI 交互模式 / `clawcode -p "指令"` 非交互模式
- 内置工具：文件操作、Shell、浏览器、子Agent、MCP

### 虚拟研发团队（/clawteam）
- 多角色并行（架构/实现/QA/交付）
- 深度循环：收敛检测、TECAP回写、回滚决策

### 设计系统（/designteam + /ui-style）
- 内置 **54个品牌设计系统**（Apple, Google, Stripe, Notion等）

### 研究子系统（Research & ResearchTeam）
- 6种工作流：deepresearch, peerreview, lit, audit, compare, teamresearch
- 多角色并行研究、合并策略

## 学习循环

```
执行任务 → 提取经验信号 → 创建ECAP → 存储
    ↑                                    ↓
    └──── 反馈评分 ← 验证结果 ← 应用ECAP ──┘
```

## 与我的关系

ClawCode 是**AI编程代理平台**，面向开发者。我（小梦）是**个人AI助理**，面向小余。
- 共同点：工具编排、记忆系统、多轮对话
- 可借鉴：记忆分层设计、多Agent协同、插件化架构
