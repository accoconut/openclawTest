#!/bin/bash
# 自动检测更改并推送到 dev 分支（SSH版本）
# 无需 token，使用 SSH 密钥认证
# 设置环境变量：
#   TEST_COMMAND: 测试命令（可选，B模式默认：npm run build）
#   BROWSER_CHECK: 是否进行浏览器检查（默认：true）

set -e

cd "$(dirname "$0")"

# 配置
REMOTE="origin"
BRANCH="dev"
TEST_CMD="${TEST_COMMAND:-npm run build}"  # B模式默认
BROWSER_CHECK="${BROWSER_CHECK:-true}"     # 默认进行浏览器检查

# 检查 SSH 连接
check_ssh() {
    echo "检查 SSH 连接到 GitHub..."
    if ssh -T git@github.com 2>&1 | grep -i "successfully authenticated" > /dev/null 2>&1; then
        echo "✅ SSH 认证成功"
        return 0
    else
        echo "❌ SSH 认证失败"
        echo "提示：请确保："
        echo "1. SSH 密钥已生成并添加到 GitHub"
        echo "2. SSH 代理正在运行（eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/你的密钥）"
        echo "3. GitHub 已添加公钥"
        return 1
    fi
}

# 检查是否有未提交的更改
if [[ -z "$(git status --porcelain)" ]]; then
    echo "没有更改，跳过"
    exit 0
fi

echo "检测到未提交的更改"

# 检查 SSH 连接（仅在需要推送时检查）
if ! check_ssh; then
    exit 1
fi

# 如果有测试命令，运行测试
if [[ -n "$TEST_CMD" ]]; then
    echo "运行测试: $TEST_CMD"
    if eval "$TEST_CMD"; then
        echo "✅ 测试通过"
    else
        echo "❌ 测试失败，停止推送"
        exit 1
    fi
fi

# 浏览器检查
if [[ "$BROWSER_CHECK" == "true" ]] || [[ "$BROWSER_CHECK" == "1" ]]; then
    echo "开始浏览器检查..."
    if [[ -f "./browser-check.sh" ]]; then
        if ./browser-check.sh; then
            echo "✅ 浏览器检查通过"
        else
            echo "❌ 浏览器检查失败，停止推送"
            exit 1
        fi
    else
        echo "⚠️  警告：browser-check.sh 不存在，跳过浏览器检查"
    fi
fi

# 提交更改
git add .
git commit -m "Auto-commit $(date '+%Y-%m-%d %H:%M:%S')"

# 推送到远程 dev 分支
echo "推送到 $REMOTE/$BRANCH (使用 SSH)"
if git push "$REMOTE" "$BRANCH"; then
    echo "✅ 推送成功"
else
    echo "❌ 推送失败"
    echo "提示：检查 SSH 密钥权限和网络连接"
    exit 1
fi

echo "✅ 已自动提交并推送到 $BRANCH 分支"