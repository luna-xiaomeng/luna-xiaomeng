"""Export session trajectory to markdown"""
import json
import os
from datetime import datetime

def extract_conversation(trajectory_path):
    messages = []
    with open(trajectory_path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except:
                continue
            
            # Extract from model.completed messagesSnapshot
            if obj.get('type') == 'model.completed' and 'data' in obj:
                d = obj['data']
                if 'messagesSnapshot' in d:
                    for m in d['messagesSnapshot']:
                        ts = m.get('timestamp', 0)
                        role = m.get('role', '?')
                        content = m.get('content', '')
                        if isinstance(content, list):
                            texts = []
                            for c in content:
                                if isinstance(c, dict):
                                    t = c.get('type', '')
                                    if t == 'text':
                                        texts.append(c.get('text', ''))
                                    elif t == 'tool_use':
                                        pass  # skip tool calls
                            content = '\n'.join(texts)
                        if role == 'user' and content:
                            try:
                                dt = datetime.fromtimestamp(ts/1000).strftime('[%Y-%m-%d %H:%M]')
                            except:
                                dt = ''
                            messages.append({'ts': ts, 'role': 'user', 'text': f"{dt} {content}"})
            
            # Extract tool call results
            if obj.get('type') == 'tool.completed' and 'data' in obj:
                d = obj['data']
                tool_name = d.get('tool', 'unknown')
                result = d.get('result', '')
                if isinstance(result, str) and len(result) > 200:
                    result = result[:200] + '...'
                elif not isinstance(result, str):
                    result = str(result)[:200]
                ts = obj.get('ts', '')
                messages.append({'ts': obj.get('seq', 0), 'role': 'tool', 'text': f"[🛠 {tool_name}] {result}"})
    
    # Sort by timestamp
    messages.sort(key=lambda x: x.get('ts', 0))
    return messages

# Main
trajectory_path = r'C:\Users\Administrator\.openclaw\agents\main\sessions\e7ba9086-3245-4159-9b04-d4ad407ba14f.trajectory.jsonl'
msgs = extract_conversation(trajectory_path)

# Write markdown
output_path = r'C:\Users\Administrator\.openclaw\workspace\对话记录_2026-05-16.md'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write('# 对话记录 - 2026-05-16\n\n')
    f.write('> 土鸡蛋AI推广视频项目\n\n')
    f.write('---\n\n')
    for m in msgs:
        if m['role'] == 'user':
            f.write(f"## 👤 你\n\n{m['text']}\n\n")
        elif m['role'] == 'tool':
            f.write(f"*{m['text']}*\n\n")
    
    # Also include memory summary
    f.write('\n---\n\n')
    f.write('# 项目总结\n\n')
    f.write('参见 memory/2026-05-16.md\n')

print(f"Exported {len(msgs)} messages to {output_path}")

# Check file size
size = os.path.getsize(output_path)
print(f"File size: {size/1024:.1f} KB")
