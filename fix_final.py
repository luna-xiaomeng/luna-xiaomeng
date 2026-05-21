import json
p = '/home/admin/.openclaw/openclaw.json'
d = json.load(open(p))

# Ensure plugin install record exists
d.setdefault('plugins', {}).setdefault('installs', {})['openclaw-weixin'] = {
    'source': 'path',
    'installPath': '/home/admin/.openclaw/extensions/openclaw-weixin',
    'version': '2.4.3',
    'installedAt': '2026-05-18T09:30:00.000Z'
}
d['plugins']['allow'] = ['openclaw-weixin', 'dashscope-cfg']
d.setdefault('plugins', {}).setdefault('entries', {})['openclaw-weixin'] = {'enabled': True}
json.dump(d, open(p, 'w'), indent=2)
print('FIXED')
