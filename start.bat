@echo off
chcp 65001 >nul
echo ========================================
echo QQ群年度报告分析器 - 一键启动脚本
echo ========================================
echo.

:: 标记是否需要用户配置
set NEED_CONFIG=0

:: 检查Python
echo [1/9] 检查Python环境...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：未找到Python，请先安装Python 3.8+
    echo 下载地址：https://www.python.org/downloads/
    pause
    exit /b 1
)
echo ✅ Python已安装

:: 检查Node.js
echo.
echo [2/9] 检查Node.js环境...
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：未找到Node.js，请先安装Node.js 16+
    echo 下载地址：https://nodejs.org/
    pause
    exit /b 1
)
echo ✅ Node.js已安装

:: 检查并配置后端.env文件
echo.
echo [3/9] 检查后端配置文件...
if not exist "backend\.env" (
    echo ⚠️  未找到backend\.env，正在创建...
    copy "backend\.env.example" "backend\.env"
    echo ✅ 已创建 backend\.env
    set NEED_CONFIG=1
) else (
    echo ✅ backend\.env 已存在
)

:: 检查并创建 config.py（命令行模式需要）
echo.
echo [4/9] 检查命令行模式配置文件...
if not exist "config.py" (
    echo ⚠️  未找到config.py，正在创建...
    copy "config.example.py" "config.py"
    echo ✅ 已创建 config.py
    set NEED_CONFIG=1
) else (
    echo ✅ config.py 已存在
)

:: 如果需要配置，提示用户并退出
if %NEED_CONFIG%==1 (
    echo.
    echo ========================================
    echo ⚠️  首次运行 - 需要配置
    echo ========================================
    echo.
    echo 已为您创建配置文件，请按以下步骤操作：
    echo.
    echo 📝 步骤1：配置 Web 模式（必需）
    echo    文件：backend\.env
    echo    说明：
    echo    - 默认使用JSON存储（无需MySQL）
    echo    - 如需MySQL，设置 STORAGE_MODE=mysql 并配置密码
    echo    - 如需AI功能，配置 OPENAI_API_KEY
    echo.
    echo 📝 步骤2：配置命令行模式（可选）
    echo    文件：config.py
    echo    说明：
    echo    - 用于直接运行 python main.py
    echo    - 修改 INPUT_FILE 为你的聊天记录路径
    echo    - 其他参数可按需调整
    echo.
    echo 💡 提示：
    echo    - 大多数用户使用 Web 模式即可（浏览器访问）
    echo    - 命令行模式适合高级用户和批量处理
    echo    - 配置完成后，再次运行 start.bat 即可
    echo.
    echo ========================================
    echo.
    pause
    exit /b 0
)

:: 继续正常启动流程
echo.
echo ✅ 配置文件检查完成，继续启动...

:: 安装Python依赖
echo.
echo [5/9] 安装Python依赖...
if not exist "venv" (
    echo 创建Python虚拟环境...
    python -m venv venv
)
call venv\Scripts\activate.bat
echo 安装后端依赖包...
pip install -r backend\requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple >nul 2>&1
if errorlevel 1 (
    echo ⚠️  使用清华源安装失败，尝试官方源...
    pip install -r backend\requirements.txt
)
echo ✅ Python依赖安装完成

:: 安装Playwright浏览器
echo.
echo [6/9] 检查Playwright浏览器...
python -c "from playwright.sync_api import sync_playwright; p = sync_playwright().start(); p.chromium.launch(headless=True); p.stop()" >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Playwright浏览器未安装，正在安装...
    echo    （首次运行需要下载约100MB，请耐心等待）
    playwright install chromium
    if errorlevel 1 (
        echo.
        echo ⚠️  Playwright浏览器安装失败
        echo    图片生成功能可能无法使用，但Web界面仍可正常运行
        echo.
    ) else (
        echo ✅ Playwright浏览器安装完成
    )
) else (
    echo ✅ Playwright浏览器已就绪
)

:: 安装前端依赖
echo.
echo [7/9] 安装前端依赖...
cd frontend
if not exist "node_modules" (
    echo 安装前端依赖包（这可能需要几分钟）...
    call npm install
    if errorlevel 1 (
        echo ❌ 错误：前端依赖安装失败
        echo 请检查网络连接或尝试使用国内镜像：
        echo npm install --registry=https://registry.npmmirror.com
        cd ..
        pause
        exit /b 1
    )
) else (
    echo ✅ 前端依赖已安装
)
cd ..
echo ✅ 前端依赖就绪

:: 检查存储模式并初始化
echo.
echo [8/9] 初始化存储...
findstr /C:"STORAGE_MODE=mysql" backend\.env >nul 2>&1
if errorlevel 1 (
    echo ✅ 使用JSON文件存储（无需数据库）
    echo    数据将保存在：runtime_outputs\reports_db\
) else (
    echo 检测到MySQL存储模式
    echo ⚠️  请确保MySQL服务已启动！
    echo.
    echo 按任意键继续初始化MySQL数据库，或Ctrl+C取消...
    pause >nul
    python backend\init_db.py
    if errorlevel 1 (
        echo.
        echo ⚠️  MySQL初始化失败！
        echo    系统将自动回退到JSON文件存储模式
        echo    如需使用MySQL，请检查：
        echo    1. MySQL服务是否已启动
        echo    2. backend\.env 中的数据库配置是否正确
        echo    3. MySQL用户是否有创建数据库的权限
        echo.
        powershell -Command "(gc backend\.env) -replace 'STORAGE_MODE=mysql', 'STORAGE_MODE=json' | Out-File -encoding ASCII backend\.env"
        echo ✅ 已切换到JSON存储模式
    ) else (
        echo ✅ MySQL数据库初始化完成
    )
)

:: 启动后端
echo.
echo [9/9] 启动服务...
echo 正在启动后端服务...
start "QQ群年度报告-后端" cmd /k "cd /d %CD% && venv\Scripts\activate.bat && python backend\app.py"
timeout /t 3 /nobreak >nul
echo ✅ 后端服务已启动（端口：5000）

:: 启动前端
echo 正在启动前端服务...
start "QQ群年度报告-前端" cmd /k "cd /d %CD%\frontend && npm run dev"
timeout /t 3 /nobreak >nul
echo ✅ 前端服务已启动（端口：5173）

echo.
echo ========================================
echo 🎉 启动完成！
echo ========================================
echo 📱 前端访问地址：http://localhost:5173
echo 🔧 后端API地址：http://localhost:5000
echo.
echo 💡 使用提示：
echo    - 两个服务窗口将保持打开状态
echo    - 关闭窗口即停止对应服务
echo    - 按Ctrl+C可停止服务
echo.
echo 📖 详细文档：README.md
echo ========================================
echo.
pause
