# -*- coding: utf-8 -*-
import re
import json
import math
from datetime import datetime, timezone, timedelta
from collections import Counter

def load_json(filepath):
    """
    使用流式解析加载 JSON 文件，减少内存占用
    对于大文件，只保留必要的字段
    """
    try:
        import ijson
        print(f"📖 使用流式解析加载 JSON 文件...")
        
        with open(filepath, 'rb') as f:
            parser = ijson.parse(f)
            result = {
                'messages': [],
                'chatName': None,
                'chatInfo': {}
            }
            
            current_message = None
            in_messages = False
            message_count = 0
            
            for prefix, event, value in parser:
                # 聊天名称
                if prefix == 'chatName' and event == 'string':
                    result['chatName'] = value
                elif prefix == 'chatInfo.name' and event == 'string':
                    result['chatInfo']['name'] = value
                
                # 开始处理 messages 数组
                elif prefix == 'messages' and event == 'start_array':
                    in_messages = True
                elif prefix == 'messages' and event == 'end_array':
                    in_messages = False
                
                # 处理单个消息
                elif in_messages:
                    if prefix == 'messages.item' and event == 'start_map':
                        current_message = {}
                        message_count += 1
                        if message_count % 10000 == 0:
                            print(f"   已处理 {message_count} 条消息...")
                    
                    elif prefix == 'messages.item' and event == 'end_map':
                        if current_message:
                            result['messages'].append(current_message)
                            current_message = None
                    
                    # 保留必要字段
                    elif current_message is not None:
                        # 消息 ID
                        if prefix == 'messages.item.messageId' and event == 'string':
                            current_message['messageId'] = value
                        
                        # 时间戳
                        elif prefix == 'messages.item.timestamp' and event in ('string', 'number'):
                            current_message['timestamp'] = str(value)
                        
                        # 发送者信息
                        elif prefix == 'messages.item.sender.uin' and event == 'string':
                            if 'sender' not in current_message:
                                current_message['sender'] = {}
                            current_message['sender']['uin'] = value
                        elif prefix == 'messages.item.sender.name' and event == 'string':
                            if 'sender' not in current_message:
                                current_message['sender'] = {}
                            current_message['sender']['name'] = value
                        
                        # 内容
                        elif prefix == 'messages.item.content.text' and event == 'string':
                            if 'content' not in current_message:
                                current_message['content'] = {}
                            current_message['content']['text'] = value
                        
                        # 回复信息
                        elif prefix == 'messages.item.content.reply.referencedMessageId' and event == 'string':
                            if 'content' not in current_message:
                                current_message['content'] = {}
                            if 'reply' not in current_message['content']:
                                current_message['content']['reply'] = {}
                            current_message['content']['reply']['referencedMessageId'] = value
                        
                        # rawMessage 中的关键字段
                        elif prefix == 'messages.item.rawMessage.subMsgType' and event == 'number':
                            if 'rawMessage' not in current_message:
                                current_message['rawMessage'] = {}
                            current_message['rawMessage']['subMsgType'] = value
                        elif prefix == 'messages.item.rawMessage.sendMemberName' and event == 'string':
                            if 'rawMessage' not in current_message:
                                current_message['rawMessage'] = {}
                            current_message['rawMessage']['sendMemberName'] = value
                        
                        # elements 数组（用于 @ 统计）
                        elif 'elements' in prefix:
                            if 'rawMessage' not in current_message:
                                current_message['rawMessage'] = {}
                            if 'elements' not in current_message['rawMessage']:
                                current_message['rawMessage']['elements'] = []
                            
                            # 简化：只保存包含 @ 的元素
                            if 'textElement.atType' in prefix and event == 'number' and value > 0:
                                element = {'elementType': 1, 'textElement': {'atType': value}}
                                current_message['rawMessage']['elements'].append(element)
                            elif 'textElement.atUid' in prefix and event == 'string':
                                if current_message['rawMessage']['elements']:
                                    current_message['rawMessage']['elements'][-1]['textElement']['atUid'] = value
        
        print(f"✅ 成功加载 {len(result['messages'])} 条消息")
        return result
        
    except ImportError:
        print("⚠️ ijson 未安装，使用标准加载（大文件可能导致内存不足）")
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            return json.load(f)
    except Exception as e:
        print(f"⚠️ 流式解析失败，尝试标准加载: {e}")
        try:
            with open(filepath, 'r', encoding='utf-8-sig') as f:
                return json.load(f)
        except MemoryError:
            print("❌ 文件过大，无法加载到内存")
            raise MemoryError("JSON 文件过大，请减小文件大小或增加系统内存")

def extract_emojis(text):
    emoji_pattern = re.compile(
        "["
        "\U0001F600-\U0001F64F"
        "\U0001F300-\U0001F5FF"
        "\U0001F680-\U0001F6FF"
        "\U0001F1E0-\U0001F1FF"
        "\U00002702-\U000027B0"
        "\U0001F900-\U0001F9FF"
        "\U0001FA00-\U0001FA6F"
        "\U0001FA70-\U0001FAFF"
        "\U00002600-\U000026FF"
        "\U00002300-\U000023FF"
        "]",
        flags=re.UNICODE
    )
    return emoji_pattern.findall(text)

def is_emoji(char):
    if len(char) != 1:
        return False
    code = ord(char)
    emoji_ranges = [
        (0x1F600, 0x1F64F), (0x1F300, 0x1F5FF), (0x1F680, 0x1F6FF),
        (0x1F1E0, 0x1F1FF), (0x2702, 0x27B0), (0x1F900, 0x1F9FF),
        (0x1FA00, 0x1FA6F), (0x1FA70, 0x1FAFF), (0x2600, 0x26FF), (0x2300, 0x23FF),
    ]
    return any(start <= code <= end for start, end in emoji_ranges)

def parse_timestamp(ts):
    try:
        dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
        local_dt = dt.astimezone(timezone(timedelta(hours=8)))
        return local_dt.hour
    except:
        return None

def clean_text(text):
    """清理文本，去除表情、@、回复等干扰内容"""
    if not text:
        return ""
    
    # 1. 去除回复标记 [回复 xxx: yyy]
    text = re.sub(r'\[回复\s+[^\]]*\]', '', text)
    
    # 2. 去除@某人（包括群昵称中的空格、括号等）
    # 匹配 @ 开头，后面的所有内容直到遇到"空格+中文/字母"（实际消息内容的开始）
    text = re.sub(r'@[^\n]*?(?=\s+[\u4e00-\u9fffa-zA-Z])', '', text)
    # 处理只有@没有后续内容的情况
    text = re.sub(r'@[^\n]*$', '', text)
    
    # 3. 循环去除所有方括号内容（如[图片][表情]等）
    prev = None
    while prev != text:
        prev = text
        text = re.sub(r'\[[^\[\]]*\]', '', text)
    
    # 4. 去除链接
    text = re.sub(r'https?://\S+', '', text)
    text = re.sub(r'www\.\S+', '', text)
    
    # 5. 去除多余空白
    text = re.sub(r'\s+', ' ', text).strip()
    
    return text

def calculate_entropy(neighbor_freq):
    total = sum(neighbor_freq.values())
    if total == 0:
        return 0
    entropy = 0
    for freq in neighbor_freq.values():
        p = freq / total
        if p > 0:
            entropy -= p * math.log2(p)
    return entropy

def generate_time_bar(hour_counts, width=20):
    max_count = max(hour_counts.values()) if hour_counts else 1
    lines = []
    for hour in range(24):
        count = hour_counts.get(hour, 0)
        bar_len = int(count / max_count * width) if max_count > 0 else 0
        bar = '█' * bar_len + '░' * (width - bar_len)
        percentage = count * 100 / sum(hour_counts.values()) if sum(hour_counts.values()) > 0 else 0
        lines.append(f"  {hour:02d}:00 {bar} {count:>5} ({percentage:>4.1f}%)")
    return lines

def sanitize_filename(filename):
    """
    清理文件名中的非法字符
    Windows文件名不允许的字符: < > : " / \\ | ? *
    保留原始字符用于显示，仅在文件名中替换
    """
    if not filename:
        return "未命名"
    
    # 替换Windows非法字符为下划线
    illegal_chars = '<>:"/\\|?*'
    sanitized = filename
    for char in illegal_chars:
        sanitized = sanitized.replace(char, '_')
    
    # 去除首尾空格和点号（Windows不允许）
    sanitized = sanitized.strip('. ')
    
    # 如果清理后为空，返回默认名称
    if not sanitized:
        return "未命名"
    
    return sanitized


def analyze_single_chars(texts):
    """分析单字的独立出现情况 - 来自旧版"""
    total_count = Counter()
    solo_count = Counter()
    boundary_count = Counter()
    punctuation = set('，。！？、；：""''（）,.!?;:\'"()[]【】《》<>…—～·')
    
    for text in texts:
        # 统计每个字的总出现次数
        for char in text:
            if re.match(r'^[\u4e00-\u9fffa-zA-Z]$', char):
                total_count[char] += 1
        
        # 统计单字消息
        clean_chars = [c for c in text if re.match(r'^[\u4e00-\u9fffa-zA-Z]$', c)]
        if len(clean_chars) == 1:
            solo_count[clean_chars[0]] += 1
        
        # 统计在边界位置的出现
        for i, char in enumerate(text):
            if not re.match(r'^[\u4e00-\u9fffa-zA-Z]$', char):
                continue
            left_ok = (i == 0) or (text[i-1] in punctuation) or (text[i-1].isspace())
            right_ok = (i == len(text)-1) or (text[i+1] in punctuation) or (text[i+1].isspace())
            if left_ok and right_ok:
                boundary_count[char] += 1
    
    result = {}
    for char in total_count:
        total = total_count[char]
        solo = solo_count[char]
        boundary = boundary_count[char]
        independent = solo + boundary * 0.5
        ratio = independent / total if total > 0 else 0
        result[char] = (total, independent, ratio)
    
    return result
