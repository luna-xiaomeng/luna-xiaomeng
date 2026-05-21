#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# OpenClaw 一键部署脚本
# 适用于: Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / Alibaba Cloud Linux
# 功能: 自动安装 Node.js + OpenClaw + 配置微信通道
# ═══════════════════════════════════════════════════════════════

set -e

# ─── 颜色 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── 配置 ───
OPENCLAW_VERSION="2026.3.28"
WORKSPACE_DIR="$HOME/.openclaw/workspace"
NODE_VERSION="22"

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     OpenClaw 一键部署脚本 v1.0      ║${NC}"
echo -e "${CYAN}║       小梦出品 · 2026-05-21         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ─── 检查系统 ───
echo -e "${YELLOW}[1/5] 检查系统环境...${NC}"
OS=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi
echo "  系统: $OS $VERSION_ID"

# ─── 安装 Node.js ───
echo -e "${YELLOW}[2/5] 安装 Node.js ${NODE_VERSION}...${NC}"
if command -v node &>/dev/null; then
    echo "  ✅ Node.js $(node -v) 已安装"
else
    echo "  📦 正在安装..."
    curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - 2>/dev/null || \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - 2>/dev/null
    if command -v yum &>/dev/null; then
        yum install -y nodejs 2>/dev/null
    else
        apt-get install -y nodejs 2>/dev/null
    fi
    echo "  ✅ Node.js $(node -v) 安装完成"
fi

# ─── 安装 OpenClaw ───
echo -e "${YELLOW}[3/5] 安装 OpenClaw...${NC}"
if command -v openclaw &>/dev/null; then
    echo "  ✅ OpenClaw $(openclaw --version 2>&1) 已安装"
else
    npm install -g openclaw 2>/dev/null
    echo "  ✅ OpenClaw 安装完成"
fi

# ─── 初始化工作区 ───
echo -e "${YELLOW}[4/5] 初始化工作区...${NC}"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"
git init 2>/dev/null
echo "  ✅ 工作区: $WORKSPACE_DIR"

# ─── 配置微信 ───
echo -e "${YELLOW}[5/5] 配置微信通道...${NC}"
echo ""
echo -e "${CYAN}══════════════════════════════════════${NC}"
echo -e "  部署完成！下一步："
echo -e "  1. 运行 ${GREEN}openclaw gateway start${NC} 启动网关"
echo -e "  2. 扫码绑定微信：${GREEN}openclaw weixin${NC}"
echo -e "  3. 查看文档: ${CYAN}https://docs.openclaw.ai${NC}"
echo -e "${CYAN}══════════════════════════════════════${NC}"
