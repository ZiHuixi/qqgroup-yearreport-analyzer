# QQ群年度报告分析器

QQ 群聊天记录分析工具，可以生成精美的年度报告。

#### ❗请注意本项目代码基于vibe coding开发，ai含量高，请酌情使用。
#### ❗该项目仍处于开发阶段，某些迭代中可能功能未完善且存在大量 Bug ，还是请酌情使用，稳定版会稍后发布release, 在线版网站正在制作中，欢迎大家提出建议。

## ✨ 核心特性

- 📊 **智能词频统计**：基于 jieba 分词的高级文本分析
- 🔍 **新词发现**：自动识别群聊专属新词
- 📈 **多维度排行榜**：发言量、活跃度、表情包、夜猫子等多个维度
- 🎨 **精美可视化报告**：自动生成 HTML/PNG 格式年度报告
- 🤖 **AI 智能点评**：集成 OpenAI API，提供 AI 年度总结（可选）
- 🎯 **交互式选词**：Web 界面支持从热词列表中自主选择展示词汇
- 💾 **数据持久化**：支持 JSON 文件或 MySQL 数据库存储
- 📜 **历史记录管理**：随时查看、搜索、删除历史报告
- 📱 **响应式设计**：完美适配各种设备
- ⚙️ **高度可定制**：丰富的配置参数，满足不同需求

## 🚀 快速开始（3步启动）

### 📋 第1步：安装必需软件

请确保已安装以下软件：

1. **Python 3.8+** （必需）
   - 下载：[python.org](https://www.python.org/downloads/)
   - 安装时勾选"Add Python to PATH"

2. **Node.js 16+** （必需）
   - 下载：[nodejs.org](https://nodejs.org/)

3. **MySQL 5.7+** （可选）
   - 下载：[mysql.com](https://dev.mysql.com/downloads/mysql/)
   - ⚡ 默认使用 JSON 文件存储，**无需安装 MySQL**

4. **qq-chat-exporter** （必需）
   - 下载：[qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter)
   - 使用该项目导出 QQ 群聊天记录为 JSON

### 🎯 第2步：启动服务

#### Windows 用户（推荐使用一键启动）

**首次运行：**

1. 双击运行 `start.bat`
2. 脚本会自动创建配置文件并提示你配置
3. 编辑配置文件（默认配置即可用，无需 MySQL）
4. 再次运行 `start.bat` 即可启动

**后续运行：**

直接双击 `start.bat` 即可启动所有服务。

#### macOS / Linux 用户
mac默认可能5000端口被占用的话换一个端口

**方式 A：手动启动前后端**

1. **启动后端**（新开一个终端）：
   ```bash
   cp config.example.py config.py
   cd backend
   pip install -r requirements.txt
   PORT=5000 python app.py
   # 如果 5000 端口被占用，会自动尝试 5001
   ```
   
2. **启动前端**（再开一个终端）：
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

3. **配置前端代理**（如果后端不是 5000 端口）：
   - 编辑 `frontend/vite.config.js`
   - 修改 `proxy.target` 为实际后端地址（如 `http://localhost:5001`）

**方式 B：使用 Docker 部署**

详见 [DOCKER.md](DOCKER.md) 文件，或执行：

```bash
# 构建并启动
docker-compose up -d --build

# 查看日志
docker-compose logs -f

# 访问 http://localhost:5001
```

### ✅ 第3步：访问应用

启动成功后，浏览器访问：

- **前端界面**：http://localhost:5173
- **后端API**：http://localhost:5000（或你配置的端口）
- **Docker 部署**：http://localhost:5001

就是这么简单！🎉

## ⚙️ 配置说明

首次运行时会自动创建两个配置文件：

### backend/.env（Web 模式配置）

```env
# 存储模式（默认使用 JSON 文件存储，无需 MySQL）
STORAGE_MODE=json

# Flask 配置
FLASK_SECRET_KEY=your_secret_key
FLASK_PORT=5000
DEBUG=false

# CORS 配置
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:5000

# OpenAI API（用于AI功能，可选）
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-3.5-turbo
```

**存储模式说明：**

- `STORAGE_MODE=json`（默认）：
  - ✅ 无需安装 MySQL
  - ✅ 数据存储在 `runtime_outputs/reports_db/` 目录
  - ✅ 适合个人本地使用
  
- `STORAGE_MODE=mysql`（可选）：
  - 适合多用户环境或生产部署
  - 需要安装 MySQL 并配置：
    ```env
    MYSQL_HOST=localhost
    MYSQL_PORT=3306
    MYSQL_USER=root
    MYSQL_PASSWORD=your_password
    MYSQL_DATABASE=qq_reports
    ```

### config.py（命令行模式配置，可选）

仅在使用命令行模式（`python main.py`）时需要配置。大多数用户使用 Web 模式即可。

## 📖 使用方式

本项目提供两种使用方式：

### 方式一：Web 界面模式（推荐）⭐

通过浏览器访问可视化界面，提供最友好的交互体验。

**使用步骤：**

**Windows 用户：**
1. 双击运行 `start.bat` 启动服务
2. 浏览器访问 http://localhost:5173
3. 上传 QQ 群聊天记录 JSON 文件
4. 选择想要展示的热词
5. 生成并查看精美报告

**macOS / Linux 用户：**
1. 按照"第2步"中的说明启动前后端服务
2. 浏览器访问 http://localhost:5173
3. 上传 QQ 群聊天记录 JSON 文件
4. 选择想要展示的热词
5. 生成并查看精美报告

### 方式二：命令行模式（高级用户）

直接通过终端运行分析脚本，适合批量处理或自动化场景。


**使用步骤：**

1. 准备聊天记录

2. 编辑 `config.py`：
   ```python
   INPUT_FILE = "path/to/your/chat.json"
   ```

3. 运行分析：
   ```bash
   python main.py
   ```

4. 查看结果：生成的报告在 `runtime_outputs` 目录

### 方式三：Docker 部署（推荐用于生产环境）

适合想要一键部署或部署到服务器的用户。

**使用步骤：**

1. **确保已安装 Docker 和 Docker Compose**
   - macOS: `brew install --cask docker`
   - Linux: 参考 [Docker 官方文档](https://docs.docker.com/get-docker/)

2. **构建并启动容器**：
   ```bash
   docker-compose up -d --build
   ```

3. **访问应用**：
   - 浏览器访问：http://localhost:5001

4. **查看日志**：
   ```bash
   docker-compose logs -f
   ```

5. **停止服务**：
   ```bash
   docker-compose down
   ```

**注意事项：**
- 首次构建需要下载依赖，可能需要 5-10 分钟
- 如果端口 5001 被占用，可修改 `docker-compose.yml` 中的端口映射
- 详细说明请参考 [DOCKER.md](DOCKER.md)

## 📊 生成的报告包含

- 📈 **基础统计**：消息总数
- 🔥 **年度热词**：群聊最热门的词汇（可自定义选择）
- 👑 **多维度排行榜**：
  - 发言量排行
  - 表情包达人
  - 夜猫子/早起人
  - 图片分享达人
- 📅 **时间分析**：活跃时段分布
- 🎭 **趣味统计**：最长发言、撤回次数等
- 🤖 **AI 点评**：对热词进行锐评（可选）

## 🛠️ 技术栈

- **后端**：Flask, Python 3.8+
- **前端**：Vue 3, Vite
- **分析引擎**：jieba（中文分词）
- **图片生成**：Playwright
- **数据存储**：JSON 文件 / MySQL（可选）
- **AI 功能**：OpenAI API（可选）

## 💾 数据存储

### JSON 文件存储（默认，推荐）

- 数据保存在 `runtime_outputs/reports_db/` 目录
- 每个报告一个 JSON 文件
- 自动创建索引文件用于快速查询
- 易于备份和迁移

### MySQL 数据库存储（可选）

- 适合多用户环境
- 支持高效查询
- 需要额外配置

## 📁 项目结构

```
QQgroup-annual-report-analyzer/
├── start.bat              # 一键启动脚本
├── README.md              # 本文档
├── config.example.py      # 命令行模式配置模板
├── main.py                # 命令行模式入口
├── requirements.txt       # Python 依赖（命令行模式）
├── analyzer.py            # 分析核心逻辑
├── report_generator.py    # 报告生成器
├── image_generator.py     # 图片导出功能
├── utils.py               # 工具函数
├── backend/               # Web 后端
│   ├── app.py            # Flask 应用
│   ├── db_service.py     # 数据库服务
│   ├── json_storage.py   # JSON 存储服务
│   ├── init_db.py        # 数据库初始化
│   ├── .env.example      # 环境变量模板
│   └── requirements.txt  # Python 依赖（Web 模式）
├── frontend/              # Web 前端
│   ├── src/              # 源代码
│   ├── package.json      # NPM 配置
│   └── vite.config.js    # Vite 配置
└── templates/             # HTML 模板
    └── report_template.html
```

## 🎯 使用建议

1. **首次使用**
   - 推荐使用 Web 模式（更直观）
   - 默认配置即可使用，无需复杂设置
   - 如需 AI 功能，配置 OpenAI API Key

2. **日常使用**
   - **Windows**：双击 `start.bat` 启动
   - **macOS/Linux**：手动启动前后端或使用 Docker
   - 在浏览器中上传聊天记录
   - 关闭服务窗口即停止服务

3. **高级用法**
   - 使用命令行模式批量处理
   - 自定义分析参数（编辑 `config.py`）
   - 部署到服务器供多人使用

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

AGPL-3.0 License

本项目采用 GNU Affero General Public License v3.0 开源协议。

**重要提示**：如果您修改本软件并通过网络提供服务，必须向用户提供修改后的完整源代码。

## 🙏 致谢

- [qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter) - QQ 聊天记录导出工具
- [jieba](https://github.com/fxsjy/jieba) - 中文分词库

## 📮 联系方式

- GitHub: [@ZiHuixi](https://github.com/ZiHuixi) & [@Jingkun Yu](https://github.com/yujingkun1)
- 项目地址: https://github.com/ZiHuixi/QQgroup-annual-report-analyzer



---

**注意**：本项目仅供学习和个人使用，请遵守相关法律法规和平台服务条款。
