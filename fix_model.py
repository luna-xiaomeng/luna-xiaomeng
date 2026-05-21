import json
with open('/home/admin/.openclaw/openclaw.json') as f:
    data = json.load(f)
data['agents']['defaults']['model']['primary'] = 'deepseek/deepseek-v4-flash'
data['agents']['defaults']['models']['deepseek/deepseek-v4-flash'] = {'alias': 'DeepSeek'}
json.dump(data, open('/home/admin/.openclaw/openclaw.json','w'), indent=2)
print('MODEL SET')
