# ClawCode 学习笔记 📚

> 学习时间：2026-05-23 19:19 ~ 19:37

## 项目概览

- **GitHub:** `github.com/deepelementlab/clawcode`（原 `instructkr/claw-code`）
- **本质：** Claude Code 的**干净室重写（Clean-room）**开源版
- **起因：** 2026.3.31 Claude Code 51万行 TypeScript 源码意外泄露，韩国开发者 Sigrid Jin（instructkr）为规避版权风险，从零重写
- **战绩：** 2小时破5万星 → 24小时超10万星 → GitHub 史上增速第一
- **名字含义：** "Craftsman's claw" — 工匠之爪，精准、持久

## 核心定位

- ✅ **不是** Claude Code 的副本，是**独立开发的兼容实现**
- ✅ **模型无关** — 支持 Claude、OpenAI、Gemini、通义千问、本地LLM
- ✅ **双语言：** Python（稳定版）→ Rust（高性能主力）
- ✅ **MIT 协议**，完全开源可商用

## 核心架构

### Python 版
```
claw-code/
├── src/main.py        # CLI入口、REPL交互
├── src/models.py      # 数据模型
├── src/commands.py    # 斜杠命令系统
├── src/tools.py       # 工具系统（40+内置工具）
├── src/query_engine.py # 查询引擎
├── src/task.py        # 任务调度
├── src/cost_tracker.py # Token消耗统计
```

### Rust 版（9个Crate）
```
api-client/     → 模型适配
runtime/        → 核心运行时、MCP编排
tools/          → 工具框架
commands/       → 命令系统
plugins/        → 插件机制
compat-harness/ → 编辑器集成
claw-cli/       → 交互式REPL
server/         → HTTP服务
lsp/            → LSP协议支持
```

## 核心功能

1. **全栈工具集成：** 40+权限控制的内置工具（文件、系统、Git、Web搜索等）
2. **多智能体协同：** Swarm模式，多Agent并行协作
3. **模型无关LLM适配层：** 统一Provider抽象，运行中可切换模型
4. **三层记忆体系：** 短期上下问 + 长期记忆 + 项目专属记忆
5. **插件化架构：** 工具插件、命令插件、运行时插件
6. **安全权限沙盒：** 敏感操作需用户授权，完整审计日志

## 应用场景

- 🔧 个人AI编程超级助手
- 👥 团队协同开发管理
- 🤖 运维自动化（Shell、日志、监控）
- 🔬 AI Agent 研究参考
- 🔒 本地离线隐私部署

## 与小梦我的关系

ClawCode 是一个 AI 编程代理框架，类似于 OpenClaw 的 Codex 插件。它和我（小梦）不一样——我是面向用户交互的个人AI助理，ClawCode 是面向开发者的AI编程Agent。但**核心思想相通**：都是AI Agent，都涉及工具编排、多轮对话、任务调度。
