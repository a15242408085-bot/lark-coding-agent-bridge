#!/bin/bash
# 一键启动脚本 - macOS
set -e

echo "🚀 Lark Coding Agent Bridge 启动中..."

# 1. 检测 node
if ! command -v node &> /dev/null; then
    echo "❌ 找不到 node，请先安装 Node.js >= 20.12.0"
    echo "   推荐用 brew install node 或 https://nodejs.org 下载安装"
    exit 1
fi
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "❌ Node 版本太低，需要 >= 20.12.0，当前是 $(node -v)"
    exit 1
fi
echo "✅ Node: $(node -v)"

# 2. 检测 agent（codex 或 claude）
AGENT=""
if command -v codex &> /dev/null; then
    AGENT="codex"
    echo "✅ 检测到 Codex CLI: $(codex --version)"
elif command -v claude &> /dev/null; then
    AGENT="claude"
    echo "✅ 检测到 Claude Code: $(claude --version)"
else
    echo "⚠️  没找到 Codex CLI 或 Claude Code"
    echo "   安装 Codex CLI: npm install -g @openai/codex"
    echo "   安装 Claude Code: npm install -g @anthropic-ai/claude-code"
    read -p "是否继续启动？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 3. 安装依赖（如果没装）
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖中..."
    npm install
fi

# 4. 构建（如果没构建）
if [ ! -d "dist" ]; then
    echo "🔨 构建中..."
    npm run build
fi

# 5. 启动
echo "🎉 启动桥接服务..."
echo ""
if [ -n "$AGENT" ]; then
    node dist/cli.js run --agent "$AGENT"
else
    node dist/cli.js run
fi
