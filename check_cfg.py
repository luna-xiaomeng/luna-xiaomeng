import json
d = json.load(open('/home/admin/.openclaw/openclaw.json'))
print('allow:', d.get('plugins',{}).get('allow',[]))
print('primary:', d.get('agents',{}).get('defaults',{}).get('model',{}).get('primary',''))
print('models:', list(d.get('agents',{}).get('defaults',{}).get('models',{}).keys()))
