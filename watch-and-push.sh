#!/bin/bash
# 监控文件变化并自动推送到 dev 分支
# 需要设置 GITHUB_TOKEN 环境变量

set -e

cd "$(dirname "$0")"

TOKEN="${GITHUB_TOKEN:-}"
if [[ -z "$TOKEN" ]]; then
    echo "错误：请设置 GITHUB_TOKEN 环境变量"
    echo "例如：export GITHUB_TOKEN=ghp_xxxx"
    exit 1
fi

REMOTE="origin"
BRANCH="dev"
CHECK_INTERVAL=${CHECK_INTERVAL:-10}  # 检查间隔（秒）
TEST_CMD="${TEST_COMMAND:-}"

echo "开始监控 React 项目更改..."
echo "分支: $BRANCH"
echo "检查间隔: ${CHECK_INTERVAL}秒"
echo "测试命令: ${TEST_CMD:-无}"
echo "按 Ctrl+C 停止"

# 设置远程仓库使用 token
REPO_URL=$(git remote get-url "$REMOTE" | sed -E 's|https?://[^/]+/|https://accoconut:'"$TOKEN"'@|')
git remote set-url "$REMOTE" "$REPO_URL"

# 捕获退出信号，恢复原始远程 URL
cleanup() {
    echo "恢复原始远程 URL..."
    ORIGINAL_URL=$(echo "$REPO_URL" | sed -E 's|https://accoconut:[^@]+@|https://|')
    git remote set-url "$REMOTE" "$ORIGINAL_URL"
    echo "监控停止"
    exit 0
}
trap cleanup INT TERM EXIT

while true; do
    # 检查是否有未提交的更改
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到更改"
        
        # 如果有测试命令，运行测试
        if [[ -n "$TEST_CMD" ]]; then
            echo "运行测试: $TEST_CMD"
            if eval "$TEST_CMD"; then
                echo "测试通过"
            else
                echo "测试失败，跳过此次推送"
                # 重置更改？暂不处理，等待用户修复
                sleep "$CHECK_INTERVAL"
                continue
            fi
        fi
        
        # 提交更改
        git add .
        git commit -m "Auto-commit $(date '+%Y-%m-%d %H:%M:%S')"
        
        # 推送到远程 dev 分支
        echo "推送到 $REMOTE/$BRANCH..."
        if git push "$REMOTE" "$BRANCH"; then
            echo "✅ 推送成功"
        else
            echo "❌ 推送失败，可能是网络问题或权限不足"
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done