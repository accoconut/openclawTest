#!/bin/bash
# 浏览器检查脚本
# 检查前端应用是否能在浏览器中正常打开且无报错
# 如果是非前端项目，自动跳过检查

set -e

cd "$(dirname "$0")"

echo "开始浏览器检查..."

# 检测是否为前端项目
is_frontend_project() {
    local frontend_indicators=0
    
    # 1. 检查是否有 package.json
    if [[ -f "package.json" ]]; then
        echo "检测到 package.json"
        
        # 检查常见前端框架关键词
        if grep -i "\"react\|\"vue\|\"angular\|\"svelte\|\"next\|\"nuxt\|\"vite\|\"webpack\|\"parcel\|\"rollup\|@angular/\|@vue/\|@svelte/" package.json > /dev/null 2>&1; then
            echo "✅ 检测到前端框架依赖"
            frontend_indicators=$((frontend_indicators + 1))
        fi
        
        # 检查是否有前端构建脚本
        if grep -i "\"build\"\|\"dev\"\|\"start\"\|\"preview\"" package.json | grep -i "vite\|webpack\|react-scripts\|next\|nuxt" > /dev/null 2>&1; then
            echo "✅ 检测到前端构建脚本"
            frontend_indicators=$((frontend_indicators + 1))
        fi
    fi
    
    # 2. 检查是否有前端入口文件
    if [[ -f "index.html" ]] || [[ -f "src/main.ts" ]] || [[ -f "src/main.tsx" ]] || [[ -f "src/main.js" ]] || [[ -f "src/main.jsx" ]] || [[ -f "src/index.ts" ]] || [[ -f "src/index.tsx" ]]; then
        echo "✅ 检测到前端入口文件"
        frontend_indicators=$((frontend_indicators + 1))
    fi
    
    # 3. 检查是否有常见前端目录结构
    if [[ -d "src" ]] && ([[ -f "src/App.tsx" ]] || [[ -f "src/App.ts" ]] || [[ -f "src/App.jsx" ]] || [[ -f "src/App.js" ]] || [[ -f "src/app.vue" ]] || [[ -f "src/App.svelte" ]]); then
        echo "✅ 检测到前端应用组件"
        frontend_indicators=$((frontend_indicators + 1))
    fi
    
    # 4. 检查是否有前端配置文件
    if [[ -f "vite.config.ts" ]] || [[ -f "vite.config.js" ]] || [[ -f "vite.config.mjs" ]] || \
       [[ -f "webpack.config.js" ]] || [[ -f "webpack.config.ts" ]] || \
       [[ -f "next.config.js" ]] || [[ -f "nuxt.config.js" ]] || \
       [[ -f "rollup.config.js" ]] || [[ -f "svelte.config.js" ]]; then
        echo "✅ 检测到前端构建配置文件"
        frontend_indicators=$((frontend_indicators + 1))
    fi
    
    # 如果没有任何前端指标，认为是非前端项目
    if [[ $frontend_indicators -eq 0 ]]; then
        echo "未检测到前端项目特征，跳过浏览器检查"
        return 1  # 不是前端项目
    else
        echo "✅ 检测为前端项目（$frontend_indicators 个特征）"
        return 0  # 是前端项目
    fi
}

# 检查是否是前端项目
if ! is_frontend_project; then
    echo "⏭️  非前端项目，跳过浏览器检查"
    exit 0  # 成功退出，表示"检查通过"
fi

echo "检测为前端项目，开始浏览器检查..."

# 方法1：检查开发服务器是否运行
DEV_SERVER_URL="http://localhost:5173"
PREVIEW_SERVER_URL="http://localhost:4173"
BUILD_SUCCESS=false
SERVER_STARTED=false

# 尝试连接开发服务器
if curl -s -f --max-time 5 "$DEV_SERVER_URL" > /dev/null 2>&1; then
    echo "✅ 开发服务器正在运行 ($DEV_SERVER_URL)"
    
    # 检查页面内容是否有明显错误
    PAGE_CONTENT=$(curl -s --max-time 10 "$DEV_SERVER_URL" | head -1000)
    
    # 检查React开发模式错误覆盖层标记
    if echo "$PAGE_CONTENT" | grep -i "error\|failed to compile\|编译错误\|syntax error" > /dev/null 2>&1; then
        echo "❌ 页面包含错误标记"
        echo "错误内容片段："
        echo "$PAGE_CONTENT" | grep -i "error\|failed to compile" | head -3
        exit 1
    fi
    
    # 检查是否有React应用的基本标记
    if echo "$PAGE_CONTENT" | grep -i "react\|vite\|root" > /dev/null 2>&1; then
        echo "✅ 页面包含前端应用标记"
    else
        echo "⚠️  警告：页面可能不是前端应用"
    fi
    
    echo "✅ 开发服务器检查通过"
    exit 0
fi

echo "开发服务器未运行，尝试构建并检查预览服务器..."

# 方法2：构建项目并检查预览服务器
if npm run build; then
    BUILD_SUCCESS=true
    echo "✅ 项目构建成功"
    
    # 启动预览服务器（后台运行）
    if grep -i "\"preview\"" package.json > /dev/null 2>&1; then
        npm run preview > /tmp/frontend-preview.log 2>&1 &
        PREVIEW_PID=$!
        
        # 等待服务器启动
        echo "等待预览服务器启动..."
        sleep 5
        
        # 检查预览服务器
        if curl -s -f --max-time 5 "$PREVIEW_SERVER_URL" > /dev/null 2>&1; then
            SERVER_STARTED=true
            echo "✅ 预览服务器启动成功 ($PREVIEW_SERVER_URL)"
            
            # 检查页面内容
            PAGE_CONTENT=$(curl -s --max-time 10 "$PREVIEW_SERVER_URL" | head -1000)
            
            # 检查是否有明显错误
            if echo "$PAGE_CONTENT" | grep -i "error\|failed\|无法加载\|加载失败" > /dev/null 2>&1; then
                echo "❌ 预览页面包含错误标记"
                # 杀死预览服务器
                kill $PREVIEW_PID 2>/dev/null || true
                exit 1
            fi
            
            # 检查是否有基本内容
            if echo "$PAGE_CONTENT" | grep -i "<html\|<!doctype\|root\|app" > /dev/null 2>&1; then
                echo "✅ 预览页面内容正常"
            else
                echo "⚠️  警告：预览页面内容异常"
            fi
            
            # 杀死预览服务器
            kill $PREVIEW_PID 2>/dev/null || true
            echo "✅ 浏览器检查通过"
            exit 0
        else
            echo "❌ 预览服务器启动失败"
            # 杀死可能挂起的进程
            kill $PREVIEW_PID 2>/dev/null || true
            exit 1
        fi
    else
        echo "⚠️  项目没有预览命令，跳过预览服务器检查"
        echo "✅ 浏览器检查通过（构建成功但未检查预览）"
        exit 0
    fi
else
    echo "❌ 项目构建失败"
    exit 1
fi