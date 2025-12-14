#!/bin/bash

# TODO 此脚本只用于启动前后端服务, 不考虑端口是否占用
# 确保脚本有执行权限: chmod +x start_project.sh

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在项目根目录
check_root_dir() {
    if [[ ! -f "config.example.py" ]] && [[ ! -d "backend" ]] && [[ ! -d "frontend" ]]; then
        print_error "请确保在项目根目录下运行此脚本！"
        print_error "当前目录: $(pwd)"
        exit 1
    fi
}

# 设置后端环境
setup_backend() {
    print_message "设置后端环境..."
    
    # 复制配置文件
    if [[ -f "config.example.py" ]]; then
        cp config.example.py config.py
        print_message "配置文件已复制: config.example.py -> config.py"
    else
        print_warning "未找到 config.example.py 文件"
    fi
    
    # 进入backend目录
    if [[ -d "backend" ]]; then
        cd backend
        
        # 检查并安装Python依赖
        if [[ -f "requirements.txt" ]]; then
            print_message "正在安装Python依赖..."
            pip install -r requirements.txt
            if [[ $? -ne 0 ]]; then
                print_warning "Python依赖安装可能有问题，请检查"
            fi
        else
            print_warning "未找到 requirements.txt 文件"
        fi
        
        # 启动后端服务（在后台运行）
        print_message "正在启动后端服务 (端口: 5000)..."
        PORT=5000 python app.py &
        BACKEND_PID=$!
        
        # 保存PID到文件，便于后续管理
        echo $BACKEND_PID > ../backend.pid
        
        # 等待后端服务启动
        sleep 3
        
        # 检查后端是否成功启动
        if ps -p $BACKEND_PID > /dev/null; then
            print_message "后端服务已启动 (PID: $BACKEND_PID)"
        else
            print_error "后端服务启动失败！"
            exit 1
        fi
        
        # 返回到项目根目录
        cd ..
    else
        print_error "未找到 backend 目录"
        exit 1
    fi
}

# 设置前端环境
setup_frontend() {
    print_message "设置前端环境..."
    
    # 进入frontend目录
    if [[ -d "frontend" ]]; then
        cd frontend
        
        # 检查并安装Node依赖
        if [[ -f "package.json" ]]; then
            print_message "正在安装Node依赖..."
            npm install
            if [[ $? -ne 0 ]]; then
                print_warning "Node依赖安装可能有问题，请检查"
            fi
        else
            print_error "未找到 package.json 文件"
            exit 1
        fi
        
        # 启动前端开发服务器
        print_message "正在启动前端开发服务器..."
        print_message "请在新终端中查看前端日志，当前终端可以继续使用..."
        
        # 在前台运行前端，这样用户可以Ctrl+C停止
        npm run dev
        
        # 返回到项目根目录
        cd ..
    else
        print_error "未找到 frontend 目录"
        exit 1
    fi
}

# 清理函数（当脚本被中断时调用）
cleanup() {
    print_message "正在停止服务..."
    
    # 停止后端服务
    if [[ -f "backend.pid" ]]; then
        BACKEND_PID=$(cat backend.pid)
        if ps -p $BACKEND_PID > /dev/null; then
            print_message "停止后端服务 (PID: $BACKEND_PID)..."
            kill $BACKEND_PID
            rm backend.pid
        fi
    fi
    
    print_message "服务已停止"
    exit 0
}

# 注册中断信号处理
trap cleanup SIGINT SIGTERM

# 主执行流程
main() {
    print_message "开始启动项目..."
    
    # 检查是否在项目根目录
    check_root_dir
    
    # 设置后端
    setup_backend
    
    # 设置前端
    setup_frontend
}

# 执行主函数
main