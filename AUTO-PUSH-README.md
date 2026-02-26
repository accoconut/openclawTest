# 自动推送设置说明（SSH持久化方案 + 智能项目检测）

根据你的要求，已配置 **SSH 持久化方案**和**智能项目检测**：
- ✅ **监控模式**：手动触发（使用 `auto-push-dev.sh`）
- ✅ **测试方式**：B模式（构建测试 + 智能浏览器检查）
- ✅ **浏览器检查**：智能检测 - 仅前端项目执行浏览器测试
- ✅ **认证方式**：SSH 密钥（无需每次输入 token）
- ✅ **项目检测**：自动识别前端/非前端项目，智能跳过不适用检查

## 🚀 快速开始（SSH方案）

### 1. 配置 SSH 密钥（如果未配置）
```bash
cd /root/.openclaw/workspace/projects/my-react-app

# 1.1 生成 SSH 密钥（如果还没有）
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -N ""

# 1.2 启动 SSH 代理并添加密钥
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github

# 1.3 查看公钥，添加到 GitHub
cat ~/.ssh/id_ed25519_github.pub
```

### 2. 将公钥添加到 GitHub
1. 访问 https://github.com/settings/keys
2. 点击 **New SSH key**
3. 粘贴公钥内容（上一步 `cat` 输出的内容）
4. 保存

### 3. 修改远程仓库为 SSH URL
```bash
# 已在当前项目中配置完成
git remote set-url origin git@github.com:accoconut/openclawTest.git
```

### 4. 运行自动化脚本（无需 token！）
```bash
# 直接运行，无需环境变量
./auto-push-dev.sh

# 或自定义配置
export TEST_COMMAND="npm run build"    # B模式：构建测试（默认）
export BROWSER_CHECK="true"            # 启用智能浏览器检查（默认）
./auto-push-dev.sh
```

## 📋 脚本工作流程（SSH版本 + 智能检测）

运行 `./auto-push-dev.sh` 时，脚本会：

1. **检查更改**：检测是否有未提交的代码更改
2. **SSH 检查**：验证 SSH 密钥认证是否正常工作
3. **构建测试**：运行 `npm run build`（B模式）
4. **项目类型检测**：智能判断是否为前端项目
5. **浏览器检查**（仅前端项目）：
   - 如果开发服务器正在运行（localhost:5173），检查页面是否可访问且无报错
   - 如果开发服务器未运行，构建项目并启动预览服务器检查
   - 检查页面内容是否有错误标记（如 "Error", "Failed to compile" 等）
6. **提交代码**：自动提交所有更改到本地仓库
7. **推送到 GitHub**：通过 SSH 推送到远程 `dev` 分支

## 🔍 智能项目检测

### 前端项目检测指标
脚本会自动检测以下特征，判断是否为前端项目：

| 检测项 | 说明 |
|--------|------|
| **前端框架依赖** | package.json 中包含 react, vue, angular, svelte, next, nuxt, vite, webpack 等 |
| **前端构建脚本** | package.json 中包含 build, dev, start, preview 等前端相关脚本 |
| **前端入口文件** | 存在 index.html, src/main.ts, src/main.tsx, src/main.js, src/main.jsx 等 |
| **前端应用组件** | src/ 目录中包含 App.tsx, App.vue, App.svelte 等组件文件 |
| **前端配置文件** | 存在 vite.config.*, webpack.config.*, next.config.js, nuxt.config.js 等 |

### 检测结果处理
- **前端项目**：执行浏览器检查，确保页面能正常打开且无报错
- **非前端项目**：跳过浏览器检查，直接进行提交和推送

## 🔧 详细配置

### 浏览器检查脚本 (`browser-check.sh`)
- **智能检测**：自动判断是否为前端项目，非前端项目直接跳过
- **检查开发服务器**：`http://localhost:5173`
- **检查预览服务器**：`http://localhost:4173`（构建后启动）
- **错误检测**：检查页面内容中的错误关键词
- **回退机制**：如果开发服务器未运行，自动构建并检查预览服务器

### 手动触发脚本 (`auto-push-dev.sh` - SSH版本)
```bash
# 环境变量配置（全部可选）
export TEST_COMMAND="npm run build"      # 默认：构建测试
export BROWSER_CHECK="true"              # 默认：启用智能浏览器检查

# 运行脚本（无需 token！）
./auto-push-dev.sh
```

## 🧪 测试场景

### 场景1：前端项目开发时（推荐）
```bash
# 1. 启动开发服务器（另一个终端）
npm run dev

# 2. 开发完成后，运行推送脚本（无需 token！）
./auto-push-dev.sh
# → 检测为前端项目，执行浏览器检查
```

### 场景2：前端项目未启动开发服务器
```bash
# 脚本会自动构建并检查预览服务器
./auto-push-dev.sh
# → 检测为前端项目，构建并检查预览服务器
```

### 场景3：非前端项目（如后端API、库）
```bash
# 脚本自动检测为非前端项目
./auto-push-dev.sh
# → 检测为非前端项目，跳过浏览器检查
# → 直接提交并推送
```

### 场景4：跳过浏览器检查（不推荐）
```bash
# 强制跳过所有浏览器检查
export BROWSER_CHECK="false"
./auto-push-dev.sh
```

## 🔐 SSH 持久化配置

### 确保 SSH 代理在每次会话中自动启动
```bash
# 添加到 ~/.bashrc 或 ~/.bash_profile
echo 'eval "$(ssh-agent -s)"' >> ~/.bashrc
echo 'ssh-add ~/.ssh/id_ed25519_github 2>/dev/null' >> ~/.bashrc
source ~/.bashrc
```

### 配置 SSH config（可选）
```bash
# 创建 ~/.ssh/config
cat >> ~/.ssh/config << EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  AddKeysToAgent yes
EOF
```

### 测试 SSH 连接
```bash
# 测试 GitHub SSH 连接
ssh -T git@github.com

# 应该看到：Hi accoconut! You've successfully authenticated...
# 如果没有，检查公钥是否已添加到 GitHub
```

## 🚨 错误处理

### SSH 认证失败
```bash
❌ SSH 认证失败
提示：请确保：
1. SSH 密钥已生成并添加到 GitHub
2. SSH 代理正在运行（eval "$(ssh-agent -s)" && ssh-add ~/.ssh/你的密钥）
3. GitHub 已添加公钥
```

### 浏览器检查失败时（仅前端项目）
如果页面包含错误，脚本会：
1. 显示错误信息
2. 停止推送
3. 返回错误代码（1）

需要你：
1. 修复代码中的错误
2. 重新运行 `./auto-push-dev.sh`

### 常见错误及解决

| 错误 | 可能原因 | 解决方案 |
|------|----------|----------|
| `❌ SSH 认证失败` | 公钥未添加到 GitHub | 添加公钥到 GitHub Settings > SSH keys |
| `❌ 浏览器检查失败` | 前端页面包含错误标记 | 检查控制台错误，修复代码 |
| `❌ 项目构建失败` | 代码有语法错误 | 运行 `npm run build` 查看详细错误 |
| `❌ 推送失败` | SSH 密钥权限问题 | 检查密钥权限：`chmod 600 ~/.ssh/id_ed25519_github` |
| `非前端项目检测` | 项目无前端特征 | 正常现象，脚本自动跳过浏览器检查 |

## 📊 验证设置

### 测试项目类型检测
```bash
# 测试当前项目的类型检测
cd /root/.openclaw/workspace/projects/my-react-app

# 应该检测为前端项目
echo "项目类型检测测试..."
if grep -i "react\|vue\|angular\|vite" package.json > /dev/null 2>&1; then
    echo "✅ 应检测为前端项目"
else
    echo "⚠️  可能检测为非前端项目"
fi
```

### 测试完整流程（前端项目）
```bash
# 1. 创建测试更改
echo "// test comment" >> src/main.ts

# 2. 运行完整脚本（无需 token！）
./auto-push-dev.sh

# 应该：
# - 检测到更改
# - SSH 检查通过
# - 构建通过
# - 检测为前端项目
# - 浏览器检查通过
# - 提交并推送到 GitHub
# - 在 https://github.com/accoconut/openclawTest/tree/dev 查看更新
```

### 测试完整流程（模拟非前端项目）
```bash
# 1. 临时重命名 package.json
mv package.json package.json.frontend

# 2. 运行脚本
./auto-push-dev.sh
# → 应检测为非前端项目，跳过浏览器检查

# 3. 恢复
mv package.json.frontend package.json
```

## 🔄 备选方案：Token 方式

如果 SSH 方案不可用，仍可使用 Token 方式：

```bash
# 使用备份的 token 版本脚本
cp auto-push-dev-token-backup.sh auto-push-dev-token.sh
chmod +x auto-push-dev-token.sh

# 设置 token 环境变量
export GITHUB_TOKEN=你的token
./auto-push-dev-token.sh
```

Token 脚本已备份为：`auto-push-dev-token-backup.sh`

## ⚙️ 高级配置

### 自定义测试命令
```bash
# 例如：添加 lint 检查
export TEST_COMMAND="npm run build && npm run lint"
./auto-push-dev.sh
```

### 调整浏览器检查
```bash
# 修改检查端口
sed -i 's/localhost:5173/localhost:3000/g' browser-check.sh

# 添加更多错误关键词
sed -i 's/error|failed to compile/error|failed|无法加载|加载失败/g' browser-check.sh
```

### 添加自定义前端检测规则
```bash
# 在 auto-push-dev.sh 和 browser-check.sh 中的 is_frontend_project() 函数
# 添加自定义检测规则，例如：
if [[ -f "custom-frontend-indicator.txt" ]]; then
    frontend_indicators=$((frontend_indicators + 1))
fi
```

## 📞 支持与故障排除

### 查看日志
```bash
# 详细输出
bash -x ./auto-push-dev.sh 2>&1 | tee push.log
```

### 检查状态
```bash
# Git 状态
git status
git log --oneline -5

# 远程分支和 URL
git remote -v
git branch -a
```

### 获取帮助
1. 查看 `memory/2026-02-26.md` - 操作记录
2. 检查 GitHub 仓库：https://github.com/accoconut/openclawTest
3. 查看脚本输出信息
4. SSH 问题：检查 `~/.ssh/` 目录权限

---

## ✅ 现在可以开始使用（SSH方案 + 智能检测）

```bash
cd /root/.openclaw/workspace/projects/my-react-app
./auto-push-dev.sh
```

每次完成代码修改并测试后，直接运行上述命令即可：
- **前端项目**：自动检测 → 构建测试 → 浏览器检查 → 推送
- **非前端项目**：自动检测 → 构建测试 → 跳过浏览器检查 → 推送

**无需每次输入 token**，**智能识别项目类型**。🎯