#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
QQ群聊年度报告生成器 - 主入口

Author: Claude Opus 4.5 & Huixi
GitHub: https://github.com/ZiHuixi/QQgroup-annual-report-analyzer
License: MIT

Usage:
    python main.py [input_file]
    
    input_file: 可选，JSON文件路径，默认读取config.py中的INPUT_FILE
"""

import sys
import os
import json

# 添加当前目录到路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import config as cfg
from utils import load_json
from analyzer import ChatAnalyzer
from report_generator import ReportGenerator
from image_generator import ImageGenerator


def main():
    """主函数"""
    # 解析命令行参数
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    else:
        input_file = cfg.INPUT_FILE
    
    # 检查文件存在
    if not os.path.exists(input_file):
        print(f"❌ 文件不存在: {input_file}")
        print(f"💡 请修改 config.py 中的 INPUT_FILE 或传入文件路径")
        sys.exit(1)
    
    print(f"📂 加载文件: {input_file}")
    
    # 加载数据
    try:
        data = load_json(input_file)
    except Exception as e:
        print(f"❌ 文件加载失败: {e}")
        sys.exit(1)
    
    # 创建分析器
    analyzer = ChatAnalyzer(data)
    
    # 执行分析
    analyzer.analyze()
    
    # 生成报告
    reporter = ReportGenerator(analyzer)
    reporter.print_console_report()
    reporter.generate_file_report()

    json_data = analyzer.export_json()
    json_path = os.path.join(
        os.path.dirname(os.path.abspath(cfg.INPUT_FILE)),
        f"{analyzer.chat_name.replace('/', '_').replace(chr(92), '_')}_分析结果.json"
    )
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(json_data, f, ensure_ascii=False, indent=2)
    print(f"📊 JSON已保存: {json_path}")
    
    # 图片生成（如果启用）
    if cfg.ENABLE_IMAGE_EXPORT:
        print("\n" + "=" * 60)
        print("🖼️  可视化报告生成")
        print("=" * 60)
        
        print("\n选择生成模式:")
        print("  1. 交互式选择热词 - 手动选择10个热词")
        print("  2. 自动选择前10 - 直接选择前10个")
        print("  3. AI智能选词 - 让AI从前200个中挑选最有趣的10个 🤖")
        print("  4. 跳过")
        
        choice = input("\n请选择 [1/2/3/4]: ").strip()
        
        if choice == '4':
            print("⏭️ 跳过可视化报告生成")
        else:
            img_gen = ImageGenerator(analyzer)
            
            if choice == '3':
                # AI 智能选词模式
                html_path, img_path = img_gen.generate(ai_select=True, enable_ai=True)
            elif choice == '2':
                # 自动选择前10
                html_path, img_path = img_gen.generate(auto_select=True, enable_ai=False)
            else:
                # 交互式选择（默认）
                html_path, img_path = img_gen.generate(auto_select=False, enable_ai=True)
            
            if html_path:
                print(f"\n📄 HTML报告: {html_path}")
            if img_path:
                print(f"🖼️ 图片报告: {img_path}")
    else:
        print("\n💡 如需生成可视化报告，请设置 ENABLE_IMAGE_EXPORT = True")
    
    print("\n" + "=" * 60)
    print("✨ 全部完成！")
    print("=" * 60)


if __name__ == '__main__':
    main()
