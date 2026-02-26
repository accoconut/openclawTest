#!/bin/bash
# 自动检测更改并推送到 dev 分支
# 设置环境变量：
#   GITHUB_TOKEN: GitHub Personal Access Token（必需）
#   TEST_COMMAND: 测试命令（可选，B模式默认：npm run build）
#   BROWSER_CHECK: 是否进行浏览器检查（默认：true）

set -e

cd "$(dirname "$0")"

# 配置
TOKEN="${GITHUB_TOKEN:-}"
REMOTE="origin"
BRANCH="dev"
TEST_CMD="${TEST_COMMAND:-npm run build}"  # B模式默认
BROWSER_CHECK="${BROWSER_CHECK:-true}"     # 默认进行浏览器检查

# 检查是否有未提交的更改
if [[ -z "$(git status --porcelain)" ]]; then
    echo "没有更改，跳过"
    exit 0
fi

echo "检测到未提交的更改"

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

# 配置远程仓库使用 token（如果提供了 token）
if [[ -n "$TOKEN" ]]; then
    REPO_URL=$(git remote get-url "$REMOTE" | sed -E 's|https?://[^/]+/|https://accoconut:'"$TOKEN"'@|')
    git remote set-url "$REMOTE" "$REPO_URL"
fi

# 提交更改
git add .
git commit -m "Auto-commit $(date '+%Y-%m-%d %H:%M:%S')"

# 推送到远程 dev 分支
echo "推送到 $REMOTE/$BRANCH"
if git push "$REMOTE" "$BRANCH"; then
    echo "✅ 推送成功"
else
    echo "❌ 推送失败"
    exit 1
fi

# 恢复原始远程 URL（避免 token 残留）
if [[ -n "$TOKEN" ]]; then
    ORIGINAL_URL=$(echo "$REPO_URL" | sed -E 's|https://accoconut:[^@]+@|https://|')
    git remote set-url "$REMOTE" "$ORIGINAL_URL"
fi

echo "✅ 已自动提交并推送到 $BRANCH 分支"