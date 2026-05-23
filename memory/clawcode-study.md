# ClawCode 学习笔记 📚

> 学习时间：2026-05-23 19:19 ~ （持续更新中）

## 项目概览

- **GitHub:** `github.com/deepelementlab/clawcode`
- **团队：** DeepElementLab（原 instructkr/claw-code 改名而来）
- **本质：** Claude Code 的**干净室重写（Clean-room）**开源版 → 现已发展为独立的 AI 编程代理平台
- **起因：** 2026.3.31 Claude Code 51万行 TypeScript 源码意外泄露，韩国开发者 Sigrid Jin（instructkr）为规避版权风险从零重写
- **战绩：** 2小时破5万星 → 24小时超10万星 → **167.4K+ ⭐**，GitHub 史上增速第一
- **名字含义：** "Craftsman's claw" — 工匠之爪，精准、持久
- **口号：** "Creative Engineering Cockpit for Serious AI Builders"
- **许可证：** GPL-3.0

## 核心定位

- ✅ **不是** Claude Code 的副本，是独立开发的原创平台
- ✅ **模型无关** — 支持 OpenAI、Claude、Gemini、本地LLM等
- ✅ **双语言：** Python（稳定版）→ 核心仍为 Python
- ✅ **终端原生执行** — 不是聊天式AI，是工程工具

## 设计哲学（四原则）

1. **执行 > 建议** — AI应该做事，不只是给建议
2. **编排 > 独白** — 多角色协作替代单Agent瓶颈
3. **学习 > 无状态** — 三层经验模型：Instinct → ECAP → TECAP
4. **平台 > 锁定** — 不绑定任何模型厂商

## 核心架构（四层）

```
┌─────────────────────────────────┐
│  Agent Runtime                  │
│  (提示执行、工具调度、会话管理)      │
├─────────────────────────────────┤
│  Workflow Engine                │
│  (阶段规划、编排、收敛、报告)       │
├─────────────────────────────────┤
│  Learning Loop                  │
│  (ECAP/TECAP 捕获、评分、复用)     │
├─────────────────────────────────┤
│  Integration Plane              │
│  (MCP + 插件钩子 + 外部适配器)     │
└─────────────────────────────────┘
```

## 记忆系统（小余说七层）

README 中描述的是 **三层经验模型（Three-tier Experience Model）**：
1. **Instinct** — 基础/本能层
2. **ECAP** — 经验胶囊（Experience Capsule）
3. **TECAP** — 团队经验胶囊（Team Experience Capsule）

但小余说是**七层记忆**，比 README 写的更细。可能还有其他层级（session、project、domain 等）。

## 核心功能

### 终端原生编码 Agent
- `clawcode` — 交互式TUI模式
- `clawcode -p "指令"` — 非交互式执行
- 内置工具：文件操作、Shell执行、浏览器自动化、子Agent、MCP集成

### 虚拟研发团队（/clawteam）
- 多角色并行（架构、实现、QA、交付）
- 深度循环模式：收敛检测、TECAP回写、回滚决策

### 设计团队（/designteam）& UI风格系统
- 内置 **54个世界级品牌设计系统**（Apple、Google Material、Stripe、Notion等）
- 风格路由：手动锁定/自动选择/混合模式

### 研究子系统（Research & ResearchTeam）
- 6种研究工作流：deepresearch、peerreview、lit、audit、compare、teamresearch
- ResearchTeam：多角色并行研究协作、合并策略（union/consensus等）

### DeepNote 知识生态
- 内置维基式知识库，支持笔记导入（Notion/Obsidian）
- 研究输出可导出到 DeepNote，再喂给 ECAP 学习

## 与我的关系

ClawCode 是 **AI 编程代理平台**，我（小梦）是 **个人AI助理**。
- 共同点：都是AI Agent，都有工具编排、记忆系统、多轮对话
- 不同点：ClawCode 面向开发者的代码工程，我面向小余的日常陪伴与帮助
- 可以学它的：记忆分层设计、多Agent协同、插件化架构
