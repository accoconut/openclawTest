# openclawTest - React 应用自动化开发工作流

这是一个使用 **OpenClaw AI 助手** 创建的 React 项目，集成了完整的自动化开发工作流。项目实现了智能代码修改、测试验证和自动提交推送功能。

## 🚀 核心功能

### 🤖 OpenClaw 自动化集成
- **AI 辅助开发**：使用 OpenClaw AI 助手自动生成和修改代码
- **智能提交**：自动检测代码更改并生成提交消息
- **一键推送**：完成修改后自动推送到 GitHub dev 分支

### 🔍 智能项目检测
- **前端项目识别**：自动检测是否为前端项目（React/Vue/Angular等）
- **差异化处理**：前端项目执行浏览器检查，非前端项目跳过
- **多特征判断**：基于依赖、配置文件、入口文件等综合判断

### 🌐 前端项目质量保障
- **构建测试**：提交前自动运行 `npm run build` 确保代码可编译
- **浏览器检查**：自动验证页面能在浏览器中正确打开且无报错
- **双重验证**：开发服务器检查 + 预览服务器检查

### 🔐 持久化认证
- **SSH 密钥认证**：无需每次输入 token，使用 SSH 密钥持久化认证
- **安全推送**：自动推送代码到 GitHub，确保权限安全

## 📋 自动化脚本

### 🎯 主脚本：`auto-push-dev.sh`
```bash
# 完整自动化工作流
./auto-push-dev.sh
```

**工作流程**：
1. **检测更改**：检查是否有未提交的代码更改
2. **SSH 认证**：验证 SSH 密钥连接到 GitHub
3. **构建测试**：运行 `npm run build` 确保代码可编译
4. **项目检测**：智能判断是否为前端项目
5. **浏览器检查**（仅前端项目）：
   - 如果开发服务器运行中 → 检查页面可访问性
   - 否则 → 构建项目并检查预览服务器
6. **自动提交**：提交所有更改到本地仓库
7. **推送代码**：推送到 GitHub dev 分支

### 🔧 辅助脚本

| 脚本 | 功能 | 使用场景 |
|------|------|----------|
| `browser-check.sh` | 浏览器检查 | 独立检查页面是否正常打开 |
| `watch-and-push.sh` | 持续监控 | 后台监控文件变化并自动推送 |
| `auto-push-dev-token-backup.sh` | Token 版本 | SSH 不可用时备用 |

## 🛠️ 快速开始

### 1. 环境准备
```bash
# 克隆项目（如果未克隆）
git clone git@github.com:accoconut/openclawTest.git
cd openclawTest

# 安装依赖
npm install
```

### 2. 开发工作流
```bash
# 方式1：开发服务器 + 手动推送
npm run dev                    # 启动开发服务器
# ... 开发代码 ...
./auto-push-dev.sh            # 自动测试并推送

# 方式2：持续监控（后台运行）
./watch-and-push.sh           # 自动监控更改并推送
```

### 3. 自定义配置
```bash
# 环境变量配置
export TEST_COMMAND="npm run build"    # 构建测试命令（默认）
export BROWSER_CHECK="true"            # 启用浏览器检查（默认）

# 运行自动化
./auto-push-dev.sh
```

## 🔍 智能项目检测详情

### 前端项目检测特征
脚本会自动检测以下特征来判断是否为前端项目：

| 检测项 | 示例特征 |
|--------|----------|
| **前端框架** | React, Vue, Angular, Svelte, Next, Nuxt |
| **构建工具** | Vite, Webpack, Parcel, Rollup |
| **入口文件** | index.html, src/main.ts, src/main.tsx |
| **应用组件** | src/App.tsx, src/App.vue, src/App.svelte |
| **配置文件** | vite.config.*, webpack.config.*, next.config.js |

### 处理逻辑
- **✅ 前端项目**：执行完整的浏览器检查流程
- **⏭️ 非前端项目**：跳过浏览器检查，直接提交推送
- **📊 智能判断**：多特征综合，避免误判

## 🌐 浏览器检查机制

### 检查流程
1. **开发服务器检查**：尝试连接 `http://localhost:5173`
2. **页面内容分析**：检查页面是否有错误标记
3. **预览服务器回退**：如果开发服务器未运行，自动构建并检查预览服务器
4. **错误检测**：识别 "Error", "Failed to compile", "无法加载" 等错误关键词

### 错误处理
- **构建失败**：停止推送，需要修复代码
- **页面错误**：停止推送，需要修复前端代码
- **服务器无法访问**：自动构建并检查预览服务器

## 🔐 SSH 持久化认证

### 已配置的 SSH 密钥
```
公钥指纹：ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7GU9yFNarNw0p7FJn2dUgD2gN1FCYZ7Iv9lQ6/ouyw
```

### 验证 SSH 连接
```bash
ssh -T git@github.com
# 输出：Hi accoconut! You've successfully authenticated...
```

### 持久化配置（推荐）
```bash
# 添加到 ~/.bashrc 确保每次会话自动加载
echo 'eval "$(ssh-agent -s)"' >> ~/.bashrc
echo 'ssh-add ~/.ssh/id_ed25519_github 2>/dev/null' >> ~/.bashrc
source ~/.bashrc
```

## 🧪 测试示例

### 测试智能检测
```bash
# 当前项目应检测为前端项目
./browser-check.sh
# 输出：✅ 检测为前端项目，开始浏览器检查...
```

### 测试完整流程
```bash
# 1. 创建测试更改
echo "// 测试自动提交" >> src/main.ts

# 2. 运行自动化脚本
./auto-push-dev.sh

# 输出流程：
# - 检测到更改
# - SSH 认证成功
# - 构建测试通过
# - 检测为前端项目
# - 浏览器检查通过
# - 自动提交并推送
```

### 模拟非前端项目
```bash
# 临时测试非前端项目检测
mv package.json package.json.backup
echo '{"name": "backend-api"}' > package.json
./auto-push-dev.sh
# 输出：⏭️ 检测为非前端项目，跳过浏览器检查
mv package.json.backup package.json
```

## 📁 项目结构

```
openclawTest/
├── src/                    # React 源码
├── dist/                   # 构建输出
├── public/                 # 静态资源
├── auto-push-dev.sh        # 主自动化脚本
├── browser-check.sh        # 浏览器检查脚本
├── watch-and-push.sh       # 持续监控脚本
├── AUTO-PUSH-README.md     # 详细自动化文档
├── package.json            # 项目依赖
├── vite.config.ts          # Vite 配置
└── README.md               # 本文件
```

## 🚨 故障排除

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| **SSH 认证失败** | 检查公钥是否添加到 GitHub Settings > SSH keys |
| **构建失败** | 运行 `npm run build` 查看详细错误信息 |
| **浏览器检查失败** | 检查开发服务器是否运行，或修复前端代码错误 |
| **推送失败** | 检查网络连接和 SSH 密钥权限 |

### 查看详细日志
```bash
# 启用调试模式
bash -x ./auto-push-dev.sh 2>&1 | tee push.log

# 检查 Git 状态
git status
git log --oneline -5
```

## 📞 支持与资源

### 相关链接
- **GitHub 仓库**：https://github.com/accoconut/openclawTest
- **Dev 分支**：https://github.com/accoconut/openclawTest/tree/dev
- **OpenClaw 文档**：https://docs.openclaw.ai

### 学习资源
- **React 官方文档**：https://reactjs.org
- **Vite 文档**：https://vitejs.dev
- **GitHub SSH 配置**：https://docs.github.com/en/authentication

## 🎯 开发理念

本项目展示了 **AI 辅助开发** 与 **自动化工作流** 的结合：

1. **智能辅助**：OpenClaw AI 助手帮助生成和优化代码
2. **质量保障**：自动化测试确保代码质量
3. **效率提升**：一键完成测试、提交、推送全流程
4. **智能适应**：根据项目类型自动调整检查策略

通过这套工作流，开发者可以专注于代码创作，让自动化工具处理繁琐的测试和部署任务。

---

**Happy coding with OpenClaw!** 🦞🚀