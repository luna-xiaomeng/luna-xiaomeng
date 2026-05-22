# 🚀 OpenClaw AI助手 一键部署使用说明

> **适用系统：** Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / Alibaba Cloud Linux  
> **脚本版本：** v1.0  
> **OpenClaw 版本：** 2026.3.28

---

## 📋 前置准备

### 你需要的
| 项目 | 说明 | 参考价格 |
|---|---|---|
| ☁️ **云服务器** | 阿里云/腾讯云/华为云，2核2G以上 | ¥99/年起 |
| 🌐 **域名**（可选） | 用于配置Webhook回调 | ¥30/年 |
| 🔑 **大模型API Key** | DeepSeek / OpenAI 等 | DeepSeek约¥10/月 |
| 📱 **微信号** | 用于扫码绑定AI助手 | 免费 |

### 推荐配置（最低成本方案）
```
阿里云轻量应用服务器（2核2G，40GB SSD）
系统：Alibaba Cloud Linux 3 / Ubuntu 22.04
费用：¥99/年 + DeepSeek API ¥10/月 ≈ ¥9/月
```

---

## 🚀 快速部署

### 第一步：登录服务器
```bash
ssh root@你的服务器IP
```

### 第二步：下载并运行脚本
```bash
git clone https://gitee.com/yuz_cn/xiaomeng-workspace.git
cd xiaomeng-workspace/products
chmod +x install-openclaw.sh
./install-openclaw.sh
```

### 第三步：配置API Key
```bash
openclaw config set model.api-key "sk-your-api-key-here"
openclaw config set model.provider "deepseek"
```

### 第四步：启动并绑定微信
```bash
openclaw gateway start          # 启动网关
openclaw login weixin           # 扫码绑定微信
```

---

## 📖 详细步骤

### 1️⃣ 购买服务器
以阿里云为例（其他云平台类似）：
1. 登录 [阿里云](https://www.aliyun.com)
2. 搜索"轻量应用服务器"
3. 选择配置：2核2G、40GB SSD、系统选 Ubuntu 22.04
4. 付款后获取公网IP和root密码

> 💡 **小贴士：** 新用户有优惠，第一年最低¥99

### 2️⃣ 服务器初始设置
```bash
# 登录服务器
ssh root@你的服务器IP

# 更新系统
apt update && apt upgrade -y

# 可选：安装必要工具
apt install -y git curl wget
```

### 3️⃣ 运行部署脚本
```bash
# 克隆仓库
git clone https://gitee.com/yuz_cn/xiaomeng-workspace.git

# 进入脚本目录
cd xiaomeng-workspace/products

# 给脚本执行权限
chmod +x install-openclaw.sh

# 运行脚本（全程自动，约2-3分钟）
./install-openclaw.sh
```

脚本会自动完成：
- ✅ 检测系统环境
- ✅ 安装 Node.js 22
- ✅ 安装 OpenClaw 最新版
- ✅ 初始化工作区

### 4️⃣ 配置AI模型
```bash
# 以DeepSeek为例
openclaw config set model.api-key "sk-你的DeepSeek密钥"
openclaw config set model.provider "deepseek"
openclaw config set model.name "deepseek-chat"

# 测试是否配置成功
openclaw chat "你好，你是谁？"
```

### 5️⃣ 绑定微信
```bash
# 启动OpenClaw网关
openclaw gateway start

# 打开微信通道
openclaw login weixin
# 会显示一个二维码，用微信扫码即可绑定
```

> ⚠️ **注意：** 扫码是一次性的，绑定后AI助手就在你的微信里了

---

## 🎯 基础使用

### 聊天对话
绑定微信后，直接给AI助手发消息即可。

### 定时播报（进阶）
配置每日播报：
```bash
openclaw cron add "0 20 * * *" "生成今日天气+新闻播报"
```

### 自定义人格
编辑工作区的 `SOUL.md` 文件自定义AI性格：
```bash
vim ~/.openclaw/workspace/SOUL.md
```

---

## 🔧 常见问题

### Q: 部署时间多久？
A: 全程约3-5分钟，主要看服务器网络速度。

### Q: 需要什么基础？
A: 会基础的Linux命令（ssh登录、复制粘贴）即可。

### Q: 支持哪些API？
A: DeepSeek、OpenAI、Claude、通义千问等。

### Q: 微信会封号吗？
A: OpenClaw使用官方微信通道，正常使用不会封号。

### Q: 部署后怎么管理？
```bash
openclaw gateway status    # 查看运行状态
openclaw gateway logs      # 查看日志
openclaw gateway restart   # 重启网关
```

### Q: 我想换模型怎么办？
```bash
openclaw config set model.provider "openai"
openclaw config set model.api-key "sk-你的OpenAI密钥"
openclaw gateway restart
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
- ✅ 30天售后答疑

---

## 📝 小贴士

1. **省钱方案：** 双十一/618买服务器最划算
2. **模型选择：** DeepSeek性价比最高，和GPT差不多效果
3. **安全注意：** 配置API Key后记得添加 `.gitignore`
4. **持久运行：** 建议用 `screen` 或 `systemd` 保持后台运行

---

> 📅 最后更新: 2026-05-22  
> 🛠️ 脚本位置: `products/install-openclaw.sh`  
> 📄 推广文: `products/v2ex-post.md`  
> 🏪 闲鱼文案: `products/xianyu-listing.md`
