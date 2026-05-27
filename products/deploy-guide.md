# 🚀 OpenClaw AI助手 一键部署使用说明

> **适用系统：** Linux 服务器 / Windows / macOS  
> **脚本版本：** v2.0（傻瓜式交互）  
> **OpenClaw 版本：** 2026.3.28

---

## 📋 前置准备

### 你需要的
| 项目 | 说明 | 参考价格 |
|---|---|---|
| ☁️ **云服务器**（推荐） | 阿里云/腾讯云/华为云，2核2G以上 | ¥99/年起 |
| 💻 **本地电脑**（可选） | Windows/Mac，长期开机即可 | 免费 |
| 🔑 **大模型API Key** | DeepSeek / OpenAI 等 | DeepSeek约¥10/月 |
| 📱 **微信号** | 用于扫码绑定AI助手 | 免费 |

### 推荐配置
```
┌─ 方案A: 云服务器（推荐）─────┐
│ 阿里云轻量 ¥99/年             │
│ + DeepSeek API ¥10/月         │
│ ≈ ¥9/月                       │
│ 7×24在线，稳定运行             │
└───────────────────────────────┘

┌─ 方案B: 本地电脑（免费）──────┐
│ 用自己的电脑（需常开机）        │
│ + Docker Desktop 免费           │
│ + DeepSeek API ¥10/月          │
│ ≈ ¥10/月                       │
│ 适合前期体验测试                 │
└───────────────────────────────┘
```

---

## 🚀 方案A：部署到云服务器（推荐）

### 第一步：购买服务器

**推荐云服务器方案（按性价比排序）：**

| 云厂商 | 最低配置 | 价格 | 购买链接 |
|---|---|---|---|
| 阿里云 | 2核2G 40GB SSD | 99/年 | [立即购买](https://www.aliyun.com/product/swas) |
| 腾讯云 | 2核2G 40GB SSD | 95/年 | [立即购买](https://cloud.tencent.com/product/lighthouse) |
| 华为云 | 2核2G 40GB SSD | 99/年 | [立即购买](https://www.huaweicloud.com/product/ecs.html) |

**购买时的关键设置：**
1. 地域：离你最近的城市（华东/华南/华北）
2. 套餐：2核2G、40GB SSD（最低配够用）
3. 镜像：Ubuntu 22.04 或 Alibaba Cloud Linux 3
4. 购买后记下 **公网IP** 和 **root密码**

> 新用户有优惠，建议趁活动买

### 第二步：登录服务器
```bash
# Windows 用 PowerShell 或 Putty
ssh root@你的服务器IP

# 首次登录会提示输入密码，输入你设置的root密码
```

### 第三步：运行傻瓜式脚本
```bash
# 下载脚本（会自动问你模型和API Key）
bash <(curl -sL https://gitee.com/yuz_cn/xiaomeng-workspace/raw/master/products/install-openclaw.sh)
```

脚本会交互式问你：
```
1️⃣ 选择AI模型（DeepSeek/OpenAI/通义千问/Claude）
2️⃣ 输入API Key
3️⃣ 自动安装 Node.js → OpenClaw → 配置工作区
4️⃣ 完成！告诉你下一步命令
```

全程傻瓜式，选完等2-3分钟就好。

### 第四步：启动并绑定微信
```bash
# 启动网关（前台运行）
openclaw gateway start

# 新开一个窗口，绑定微信
openclaw plugins.weixin.login

# 会显示二维码，用微信扫码即可
```

### 第五步：开机自启（重要）
```bash
# 使用 systemd 保持后台运行
sudo tee /etc/systemd/system/openclaw.service > /dev/null << EOF
[Unit]
Description=OpenClaw AI Gateway
After=network.target

[Service]
Type=simple
User=root
ExecStart=$(which openclaw) gateway start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
```

---

## 🚀 方案B：部署到本地电脑

### Windows 部署（使用 WSL）

> WSL = Windows Subsystem for Linux，能在Windows里直接运行Linux

```bash
# 1️⃣ 安装 WSL（需要Windows 10/11）
#    右键「开始」→「Windows PowerShell (管理员)」，运行：
wsl --install -d Ubuntu-22.04

# 2️⃣ 重启电脑
#    WSL会自动安装完成，首次启动会让你设置Linux用户名和密码

# 3️⃣ 更新软件源
sudo apt update && sudo apt upgrade -y

# 4️⃣ 安装必要工具
sudo apt install -y curl git screen

# 5️⃣ 运行傻瓜式脚本
bash <(curl -sL https://gitee.com/yuz_cn/xiaomeng-workspace/raw/master/products/install-openclaw.sh)
```

> 📥 WSL官方文档: https://learn.microsoft.com/zh-cn/windows/wsl/install

### macOS 部署

```bash
# 1️⃣ 安装 Homebrew（如果没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2️⃣ 安装 Node.js
brew install node@22

# 3️⃣ 安装 OpenClaw
npm install -g openclaw

# 4️⃣ 运行傻瓜式脚本
bash <(curl -sL https://gitee.com/yuz_cn/xiaomeng-workspace/raw/master/products/install-openclaw.sh)
```

### Mac/Windows 纯Docker方案

```bash
# 1️⃣ 安装 Docker Desktop
#    Windows: https://docs.docker.com/desktop/install/windows-install/
#    macOS:   https://docs.docker.com/desktop/install/mac-install/

# 2️⃣ 运行 OpenClaw（一行命令）
docker run -d \
  --name openclaw \
  -p 8080:8080 \
  -v ~/.openclaw:/root/.openclaw \
  openclaw/openclaw:latest
```

---

## 🔧 脚本交互说明

运行 `install-openclaw.sh` 后，脚本会逐步引导你：

```
[1/6] 检测系统环境
  ✅ 自动识别操作系统和架构

[2/6] 选择AI模型
  1) DeepSeek（推荐，性价比最高）
  2) OpenAI
  3) 通义千问
  4) Claude
  5) 自定义
  → 输入编号即可

[3/6] 输入API Key
  → 粘贴你的API Key（不会泄露）

[4/6] 安装 Node.js
  → 自动检测并安装

[5/6] 安装 OpenClaw
  → 自动安装最新版

[6/6] 配置工作区
  → 自动写入配置文件

🎉 部署完成！
```

---

## 🔑 各大模型API Key获取

### DeepSeek（推荐）
```
1. 打开 https://platform.deepseek.com/api_keys
2. 注册/登录账号
3. 点击"创建API Key"
4. 复制以 sk- 开头的密钥
```

### OpenAI
```
1. 打开 https://platform.openai.com/api-keys
2. 注册/登录（需海外手机号）
3. 点击"Create new secret key"
4. 复制密钥（以 sk- 开头）
```

### 通义千问（阿里云）
```
1. 打开 https://bailian.console.aliyun.com/
2. 注册阿里云并登录
3. 开通"百炼"服务
4. 在API Key管理页面创建密钥
```

### Claude (Anthropic)
```
1. 打开 https://console.anthropic.com/
2. 注册/登录
3. 在API Keys页面创建密钥
```

---

## 🎯 基础使用

### 聊天对话
微信扫码绑定后，直接给AI助手发消息即可。

### 查看运行状态
```bash
openclaw gateway status     # 运行状态
openclaw gateway logs       # 查看日志
```

### 自定义AI人格
```bash
vim ~/.openclaw/workspace/SOUL.md
```

---

## 🔧 常见问题

### Q: 部署时间多久？
A: 全程约3-5分钟，主要看服务器网络速度。

### Q: 微信会封号吗？
A: OpenClaw使用官方微信通道，正常使用不会封号。

### Q: 部署后怎么管理？
```bash
# 云服务器
ssh root@你的服务器IP
sudo systemctl status openclaw   # 查看状态
sudo systemctl restart openclaw  # 重启

# 本地
openclaw gateway start           # 启动
openclaw gateway stop            # 停止
```

### Q: 换模型怎么办？
```bash
openclaw config set model.provider "openai"
openclaw config set model.api-key "sk-你的新密钥"
openclaw config set model.name "gpt-4o-mini"
openclaw gateway restart
```

### Q: 忘记API Key了？
```bash
cat ~/.openclaw/gateway.yaml   # 查看当前配置
```

### Q: 需要开放哪些端口？
```
- SSH: 22（登录用）
- OpenClaw: 8080（API服务）
- 微信Webhook: 需要公网IP或内网穿透
```

---

## 📊 定价参考

### 基础版 ¥99（自助）
- ✅ 一键部署脚本
- ✅ 详细图文教程
- ✅ 微信绑定指南
- ✅ 基础AI对话功能

### 高级版 ¥199（含远程协助）
- ✅ 基础版全部内容
- ✅ 远程连接到你的服务器代部署
- ✅ 定制AI人格（名字/性格/语气）
- ✅ 配置定时播报功能
- ✅ 开机自启配置
- ✅ 30天售后答疑

---

## 📝 小贴士

1. **省钱方案：** 双十一/618买服务器最划算，DeepSeek模型最便宜
2. **安全注意：** 配置API Key后记得不要泄露配置文件
3. **持久运行：** 云服务器推荐配置systemd自启
4. **本地测试：** 先用本地电脑测试，满意再买服务器
5. **多模型：** 可以同时配置多个模型，随时切换

---

> 📅 最后更新: 2026-05-22  
> 🛠️ 脚本位置: `products/install-openclaw.sh`  
> 📄 快速命令: `bash <(curl -sL https://gitee.com/yuz_cn/xiaomeng-workspace/raw/master/products/install-openclaw.sh)`
