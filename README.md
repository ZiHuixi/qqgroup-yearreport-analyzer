# 🎉 QQ群聊年度报告分析器

一个用于分析QQ群聊记录并生成年度热词报告的工具。支持热词发现、趣味统计、可视化报告生成等功能。前后端一体：上传 qq-chat-exporter 导出的 JSON，即可在 Web 端完成分析，也可命令行直接运行。

![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ 功能特点

- 🔍 **智能分词**：基于 jieba，支持新词发现与高频词组合并
- 📊 **热词统计**：高频词、贡献者、样例句
- 🎮 **趣味榜单**：话痨/字数/长文/表情/图片/深夜党/早起鸟/复读机等
- ⏰ **时段分析**：24 小时活跃分布
- 🖼️ **可视化报告**：生成 HTML，可选 PNG
- 🤖 **AI 锐评**：支持 OpenAI 接口（可选）

## 📦 安装

### 1. 克隆项目
```bash
git clone https://github.com/ZiHuixi/QQgroup-annual-report-analyzer.git
cd QQgroup-annual-report-analyzer
```

### 2. 后端依赖
```bash
cd backend
pip install -r requirements.txt
```

### 3. 前端依赖
```bash
cd ../frontend
npm install
```

### 4. 可选：图片导出（Playwright）
```bash
pip install playwright
playwright install chromium
```

## 🚀 使用方法

### 获取群聊数据
推荐使用 [qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter) 导出 QQ 群聊记录为 JSON。

### A. 本地前后端模式（推荐）
1) 后端
```bash
cd backend
python app.py         # 若 5000 占用会自动尝试 5001
```
2) 前端（新终端）
```bash
cd frontend
npm run dev           # 默认 5173，已代理到 http://localhost:5000
```
3) 浏览器打开 `http://localhost:5173`，上传 JSON，调整参数后点击分析。

### B. 纯命令行模式
```bash
# 默认读取 config.py 中的 INPUT_FILE
python main.py
# 或指定文件
python main.py your_chat.json
```

## ⚙️ 配置说明（核心项）
编辑 `config.py`（后端 API 可通过 options 覆盖）：
```python
INPUT_FILE = "chat.json"
TOP_N = 200
NEW_WORD_MIN_FREQ = 20
PMI_THRESHOLD = 2.0
ENTROPY_THRESHOLD = 0.5
MERGE_MIN_FREQ = 30
MERGE_MIN_PROB = 0.3
ENABLE_IMAGE_EXPORT = False  # 服务端无 chromium 时建议 False
OPENAI_API_KEY = ""          # 可选，用于 AI 锐评
OPENAI_BASE_URL = ""
OPENAI_MODEL = ""
```

## 🖥️ 前端可调参数
- TOP_N、新词频次、PMI/熵阈值、合并频次/概率
- 是否生成图片（需后端 Playwright + Chromium）

## 📋 输出文件
- `xxx_年度热词报告.txt`：文本报告
- `xxx_分析结果.json`：结构化数据（含榜单/时段分布/样例）
- `xxx_年度热词报告.html`：HTML 可视化报告
- `xxx_年度热词报告.png`：图片报告（可选）

## ☁️ 部署示例（Render 免费）
- Build: `cd frontend && npm install && npm run build && cd ../backend && pip install -r requirements.txt`
- Start: `cd backend && gunicorn app:app --bind 0.0.0.0:$PORT`
- 如需一体化托管，可将 `frontend/dist` 作为 Flask 静态目录提供。
- 若无 Chromium，请设 `ENABLE_IMAGE_EXPORT=false`。

## ⚠️ 注意事项
- 分词基于统计方法，建议配置 `BLACKLIST`/`WHITELIST` 过滤无意义词。
- AI 锐评需配置 OpenAI Key；未配置会使用默认文案。
- 大文件上传受部署平台限制，必要时调大请求体大小或改用对象存储。

## 🛠️ 项目结构
```
QQgroup-annual-report-analyzer/
├── backend/            # Flask API
├── frontend/           # Vite + Vue 前端
├── main.py             # CLI 入口
├── analyzer.py         # 核心分析
├── report_generator.py # 文本报告
├── image_generator.py  # HTML/PNG 报告
├── config.py|example   # 配置
├── templates/          # HTML 模板
└── README.md
```

## 📄 许可证
MIT License

## 🤝 贡献
欢迎 Issue / PR！

## 致谢
- [jieba](https://github.com/fxsjy/jieba) - 中文分词
- [qq-chat-exporter](https://github.com/shuakami/qq-chat-exporter) - QQ聊天记录导出
- [Playwright](https://playwright.dev/) - 网页截图