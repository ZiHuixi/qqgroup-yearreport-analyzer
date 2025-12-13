#!/bin/bash
# QQ群年度报告分析器 - Linux 生产环境一键部署脚本
# 适用于 Ubuntu 20.04+ / Debian 11+ / CentOS 8+

set -e  
echo "========================================"
echo "QQ群年度报告分析器 - 生产环境部署"
echo "========================================"

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "❌ 无法检测操作系统"
    exit 1
fi

echo "📋 检测到系统: $OS $VER"

install_dependencies() {
    echo ""
    echo "📦 安装系统依赖..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt update || echo "⚠️ apt update 失败，继续尝试安装"
        sudo apt install -y python3 python3-pip python3-venv nodejs npm nginx certbot python3-certbot-nginx git redis-server mysql-server || echo "⚠️ 部分软件包安装失败，请检查"
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
        sudo yum install -y python3 python3-pip nodejs npm nginx certbot python3-certbot-nginx git redis mysql-server || echo "⚠️ 部分软件包安装失败，请检查"
    else
        echo "⚠️ 不支持的操作系统: $OS"
        echo "请手动安装以下依赖: python3, python3-pip, python3-venv, nodejs, npm, nginx, certbot, git, redis, mysql"
        read -p "是否继续部署？(y/n): " continue_anyway
        if [ "$continue_anyway" != "y" ]; then
            exit 1
        fi
    fi
    
    echo "✅ 系统依赖安装完成"
}


# 创建部署用户
create_deploy_user() {
    echo ""
    echo "👤 创建部署用户..."
    
    if id "qqreport" &>/dev/null; then
        echo "✅ 用户 qqreport 已存在"
    else
        sudo useradd -m -s /bin/bash qqreport
        echo "✅ 已创建用户 qqreport"
    fi
}

# 克隆项目
clone_project() {
    echo ""
    echo "📥 克隆项目..."
    
    DEPLOY_DIR="/opt/qqgroup-annual-report-analyzer"
    
    if [ -d "$DEPLOY_DIR" ]; then
        echo "⚠️ 目录已存在，正在更新..."
        cd $DEPLOY_DIR
        sudo -u qqreport git pull
    else
        sudo mkdir -p /opt
        sudo git clone https://github.com/ZiHuixi/QQgroup-annual-report-analyzer.git $DEPLOY_DIR
        sudo chown -R qqreport:qqreport $DEPLOY_DIR
    fi
    
    cd $DEPLOY_DIR
    echo "✅ 项目已克隆到 $DEPLOY_DIR"
}

# 配置 Python 环境
setup_python_env() {
    echo ""
    echo "🐍 配置 Python 虚拟环境..."
    
    cd /opt/qqgroup-annual-report-analyzer
    
    if [ ! -d "venv" ]; then
        sudo -u qqreport python3 -m venv venv
    fi
    
    sudo -u qqreport venv/bin/pip install --upgrade pip
    sudo -u qqreport venv/bin/pip install -r backend/requirements.txt
    sudo -u qqreport venv/bin/playwright install chromium
    sudo -u qqreport venv/bin/playwright install-deps
    
    echo "✅ Python 环境配置完成"
}

# 配置前端
setup_frontend() {
    echo ""
    echo "⚛️ 构建前端..."
    
    cd /opt/qqgroup-annual-report-analyzer/frontend
    
    sudo -u qqreport npm install
    sudo -u qqreport npm run build
    
    echo "✅ 前端构建完成"
}

# 配置环境变量
setup_env() {
    echo ""
    echo "🔧 配置环境变量..."
    
    cd /opt/qqgroup-annual-report-analyzer
    
    # 配置 config.py
    if [ ! -f "config.py" ]; then
        sudo -u qqreport cp config.example.py config.py
        echo "⚠️ 请编辑 config.py 文件，配置 OpenAI API 密钥等参数"
        echo "   执行: sudo nano /opt/qqgroup-annual-report-analyzer/config.py"
    fi
    
    if [ ! -f "backend/.env" ]; then
        sudo -u qqreport cp backend/.env.example backend/.env
        
        # 生成随机密钥
        SECRET_KEY=$(openssl rand -hex 32)
        sudo -u qqreport sed -i "s/your-secret-key-here/$SECRET_KEY/" backend/.env
        
        echo "⚠️ 请编辑 backend/.env 文件，配置数据库和 OpenAI API 密钥"
        echo "   执行: sudo nano /opt/qqgroup-annual-report-analyzer/backend/.env"
    fi
    
    if [ ! -f "frontend/.env" ]; then
        sudo -u qqreport cp frontend/.env.example frontend/.env
    fi
    
    echo "✅ 环境变量已配置"
}

# 初始化数据库
init_database() {
    echo ""
    echo "🗄️ 初始化数据库..."
    
    cd /opt/qqgroup-annual-report-analyzer
    
    echo "请选择存储模式："
    echo "1) MySQL（推荐，生产环境）"
    echo "2) JSON文件（适合测试）"
    read -p "请输入选项 [1/2]: " storage_choice
    
    if [ "$storage_choice" == "1" ]; then
        echo "📝 配置 MySQL..."
        echo "请输入 MySQL root 密码："
        read -s MYSQL_ROOT_PASSWORD
        
        mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS qqreport CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'qqreport'@'localhost' IDENTIFIED BY 'secure_password_here';
GRANT ALL PRIVILEGES ON qqreport.* TO 'qqreport'@'localhost';
FLUSH PRIVILEGES;
EOF
        
        sudo -u qqreport venv/bin/python backend/init_db.py
        echo "✅ MySQL 数据库初始化完成"
    else
        echo "✅ 使用 JSON 文件存储模式"
    fi
}

# 配置 Systemd 服务
setup_systemd() {
    echo ""
    echo "⚙️ 配置 Systemd 服务..."
    
    sudo tee /etc/systemd/system/qqreport.service > /dev/null <<EOF
[Unit]
Description=QQ Group Annual Report Analyzer
After=network.target mysql.service redis.service

[Service]
Type=exec
User=qqreport
Group=qqreport
WorkingDirectory=/opt/qqgroup-annual-report-analyzer
Environment="PATH=/opt/qqgroup-annual-report-analyzer/venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/opt/qqgroup-annual-report-analyzer/venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 --timeout 300 backend.app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable qqreport
    
    echo "✅ Systemd 服务已配置"
}

# 配置 Nginx
setup_nginx() {
    echo ""
    echo "🌐 配置 Nginx..."
    
    read -p "请输入你的域名: " DOMAIN
    
    sudo tee /etc/nginx/sites-available/qqreport > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    client_max_body_size 1024M;
    
    # 安全头
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
    }

    location /static {
        alias /opt/qqgroup-annual-report-analyzer/frontend/dist;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    sudo ln -sf /etc/nginx/sites-available/qqreport /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    
    echo "✅ Nginx 已配置"
    
    # 配置 SSL
    read -p "是否配置 SSL 证书？(y/n): " setup_ssl
    if [ "$setup_ssl" == "y" ]; then
        sudo certbot --nginx -d $DOMAIN
        echo "✅ SSL 证书已配置"
    fi
}

# 启动服务
start_services() {
    echo ""
    echo "🚀 启动服务..."
    
    sudo systemctl start redis
    sudo systemctl start mysql
    sudo systemctl start qqreport
    sudo systemctl start nginx
    
    echo "✅ 所有服务已启动"
}

# 显示状态
show_status() {
    echo ""
    echo "========================================"
    echo "📊 部署状态"
    echo "========================================"
    
    echo ""
    echo "服务状态："
    sudo systemctl status qqreport --no-pager | grep Active
    sudo systemctl status nginx --no-pager | grep Active
    
    echo ""
    echo "🎉 部署完成！"
    echo ""
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):80"
    echo "日志查看: sudo journalctl -u qqreport -f"
    echo "服务管理:"
    echo "  - 启动: sudo systemctl start qqreport"
    echo "  - 停止: sudo systemctl stop qqreport"
    echo "  - 重启: sudo systemctl restart qqreport"
    echo "  - 状态: sudo systemctl status qqreport"
    echo ""
    echo "更新应用:"
    echo "  cd /opt/qqgroup-annual-report-analyzer"
    echo "  sudo -u qqreport git pull"
    echo "  sudo systemctl restart qqreport"
    echo ""
}

# 主函数
main() {
    echo ""
    read -p "开始部署？这将安装所有必要的组件。(y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo "❌ 取消部署"
        exit 0
    fi
    
    install_dependencies
    create_deploy_user
    clone_project
    setup_python_env
    setup_frontend
    setup_env
    init_database
    setup_systemd
    setup_nginx
    start_services
    show_status
}

# 运行主函数
main
