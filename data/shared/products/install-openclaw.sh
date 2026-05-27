#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# OpenClaw 傻瓜式一键部署脚本 v2.0
# 全程交互，只需选择模型 + 输入API Key，其余全自动
# 适用: Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / Alibaba Cloud Linux
# ═══════════════════════════════════════════════════════════════

set -e

# ─── 颜色 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ─── 横幅 ───
clear
echo -e "${MAGENTA}"
echo '  ╔══════════════════════════════════════╗'
echo '  ║     🌸 OpenClaw 傻瓜式一键部署       ║'
echo '  ║       小梦出品 · 全程自动            ║'
echo '  ╚══════════════════════════════════════╝'
echo -e "${NC}"
echo ""

# ─── 步骤1: 系统检测 ───
echo -e "${YELLOW}[1/6] 检测系统环境...${NC}"
OS=""
OS_VERSION=""
ARCH=$(uname -m)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
fi

if [ -z "$OS" ]; then
    echo -e "${RED}  ❌ 无法识别操作系统，脚本仅支持 Linux${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ 系统: $OS $OS_VERSION ($ARCH)${NC}"

# 检查是否为 root
if [ "$(id -u)" != "0" ]; then
    echo -e "${YELLOW}  ⚠️  建议以 root 用户运行，部分步骤可能需要 sudo${NC}"
fi

# ─── 步骤2: 选择AI模型 ───
echo ""
echo -e "${YELLOW}[2/6] 选择AI模型...${NC}"
echo ""
echo "  支持的模型:"
echo "  ${CYAN}1)${NC} DeepSeek（推荐，性价比最高，¥10/月）"
echo "  ${CYAN}2)${NC} OpenAI（GPT-4o / GPT-4o-mini）"
echo "  ${CYAN}3)${NC} 通义千问（阿里云，国内免翻墙）"
echo "  ${CYAN}4)${NC} Claude（Anthropic，编程能力强）"
echo "  ${CYAN}5)${NC} 自定义（自行配置）"
echo ""
read -p "  请输入编号 [1-5]（默认1）: " MODEL_CHOICE
MODEL_CHOICE=${MODEL_CHOICE:-1}

case $MODEL_CHOICE in
    1)
        PROVIDER="deepseek"
        MODEL="deepseek-chat"
        API_URL="https://api.deepseek.com"
        echo -e "${GREEN}  ✅ 已选择: DeepSeek${NC}"
        echo -e "  ${YELLOW}📌 获取API Key: https://platform.deepseek.com/api_keys${NC}"
        ;;
    2)
        PROVIDER="openai"
        MODEL="gpt-4o-mini"
        API_URL="https://api.openai.com"
        echo -e "${GREEN}  ✅ 已选择: OpenAI${NC}"
        echo -e "  ${YELLOW}📌 获取API Key: https://platform.openai.com/api-keys${NC}"
        ;;
    3)
        PROVIDER="dashscope"
        MODEL="qwen-plus"
        API_URL="https://dashscope.aliyuncs.com"
        echo -e "${GREEN}  ✅ 已选择: 通义千问${NC}"
        echo -e "  ${YELLOW}📌 获取API Key: https://bailian.console.aliyun.com/${NC}"
        ;;
    4)
        PROVIDER="anthropic"
        MODEL="claude-sonnet-4-20250514"
        API_URL="https://api.anthropic.com"
        echo -e "${GREEN}  ✅ 已选择: Claude${NC}"
        echo -e "  ${YELLOW}📌 获取API Key: https://console.anthropic.com/${NC}"
        ;;
    5)
        echo ""
        read -p "  请输入Provider名称: " PROVIDER
        read -p "  请输入模型名称: " MODEL
        read -p "  请输入API地址: " API_URL
        echo -e "${GREEN}  ✅ 已选择自定义: $PROVIDER / $MODEL${NC}"
        ;;
    *)
        PROVIDER="deepseek"
        MODEL="deepseek-chat"
        API_URL="https://api.deepseek.com"
        echo -e "${GREEN}  ✅ 已选择默认: DeepSeek${NC}"
        ;;
esac

# ─── 步骤3: 输入API Key ───
echo ""
echo -e "${YELLOW}[3/6] 输入API Key...${NC}"
echo -e "  ${YELLOW}⚠️  Key不会被保存到脚本中，仅写入OpenClaw配置${NC}"
echo ""
read -p "  请输入你的API Key: " API_KEY
if [ -z "$API_KEY" ]; then
    echo -e "${RED}  ❌ API Key 不能为空！${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ API Key 已录入${NC}"

# ─── 步骤4: 安装 Node.js ───
echo ""
echo -e "${YELLOW}[4/6] 安装 Node.js 22...${NC}"
if command -v node &>/dev/null; then
    NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VER" -ge 18 ]; then
        echo -e "${GREEN}  ✅ Node.js $(node -v) 已满足要求${NC}"
    else
        echo -e "${YELLOW}  ⚠️  Node.js $(node -v) 版本过低，需要升级${NC}"
        INSTALL_NODE=true
    fi
else
    INSTALL_NODE=true
fi

if [ "$INSTALL_NODE" = true ]; then
    echo "  📦 正在安装 Node.js 22..."
    # 尝试多种包管理器
    if command -v yum &>/dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - 2>/dev/null
        yum install -y nodejs 2>/dev/null
    elif command -v apt &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash - 2>/dev/null
        apt-get install -y nodejs 2>/dev/null
    elif command -v apk &>/dev/null; then
        apk add nodejs 2>/dev/null
    else
        echo -e "${RED}  ❌ 无法安装 Node.js，请手动安装${NC}"
        exit 1
    fi
    
    if command -v node &>/dev/null; then
        echo -e "${GREEN}  ✅ Node.js $(node -v) 安装完成${NC}"
    else
        echo -e "${RED}  ❌ Node.js 安装失败，请手动安装${NC}"
        exit 1
    fi
fi

# ─── 步骤5: 安装 OpenClaw ───
echo ""
echo -e "${YELLOW}[5/6] 安装 OpenClaw...${NC}"
if command -v openclaw &>/dev/null; then
    echo -e "${GREEN}  ✅ OpenClaw $(openclaw --version 2>&1 | head -1) 已安装${NC}"
else
    echo "  📦 正在安装 OpenClaw..."
    npm install -g openclaw 2>&1 | tail -1
    if command -v openclaw &>/dev/null; then
        echo -e "${GREEN}  ✅ OpenClaw 安装完成${NC}"
    else
        echo -e "${RED}  ❌ OpenClaw 安装失败${NC}"
        echo "  尝试: npm install -g openclaw"
        exit 1
    fi
fi

# ─── 步骤6: 配置工作区 ───
echo ""
echo -e "${YELLOW}[6/6] 配置工作区...${NC}"

WORKSPACE_DIR="$HOME/.openclaw/workspace"
mkdir -p "$WORKSPACE_DIR"

# 写入网关配置
CONFIG_FILE="$HOME/.openclaw/gateway.yaml"
mkdir -p "$(dirname "$CONFIG_FILE")"

cat > "$CONFIG_FILE" << GATEWAY_EOF
# OpenClaw 网关配置 — 由小梦部署脚本自动生成
model:
  provider: ${PROVIDER}
  name: ${MODEL}
  apiKey: ${API_KEY}
  apiUrl: ${API_URL}

gateway:
  port: 8080
  host: "0.0.0.0"

plugins:
  weixin:
    enabled: true
GATEWAY_EOF

echo -e "${GREEN}  ✅ 配置文件已写入: $CONFIG_FILE${NC}"

# ─── 完成 ───
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         🎉 部署完成！                ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  模型: ${GREEN}${PROVIDER} / ${MODEL}${NC}"
echo ""
echo -e "  ${MAGENTA}下一步操作：${NC}"
echo -e "  ${CYAN}1)${NC} 启动网关:    ${GREEN}openclaw gateway start${NC}"
echo -e "  ${CYAN}2)${NC} 绑定微信:    ${GREEN}openclaw plugins.weixin.login${NC}"
echo -e "  ${CYAN}3)${NC} 测试对话:    ${GREEN}openclaw chat '你好'${NC}"
echo -e "  ${CYAN}4)${NC} 查看状态:    ${GREEN}openclaw gateway status${NC}"
echo ""
echo -e "  ${YELLOW}💡 保持后台运行:${NC}"
echo -e "     screen -S openclaw ${GREEN}openclaw gateway start${NC}"
echo ""

# 写入版本信息
echo -e "🤖 OpenClaw 小梦版 v1.0 | 部署于 $(date '+%Y-%m-%d %H:%M')" > "$WORKSPACE_DIR/.deploy-info"
echo -e "${GREEN}  ✅ 全部完成！祝你使用愉快 🌸${NC}"
