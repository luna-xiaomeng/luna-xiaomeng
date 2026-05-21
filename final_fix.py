import json
p = '/home/admin/.openclaw/openclaw.json'
d = json.load(open(p))

# Register weixin channel directly with full install record
d['plugins']['installs']['openclaw-weixin'] = {
    'source': 'path',
    'installPath': '/home/admin/.openclaw/extensions/openclaw-weixin',
    'version': '2.4.3',
    'installedAt': '2026-05-18T09:32:00.000Z'
}
d['plugins']['allow'] = ['openclaw-weixin', 'dashscope-cfg']
d['plugins']['entries']['openclaw-weixin'] = {'enabled': True}
d['channels']['openclaw-weixin'] = {'enabled': True}

# Also add openclaw-weixin to plugins.installs tracking
d['plugins']['installs']['openclaw-weixin'] = {
    'source': 'path',
    'installPath': '/home/admin/.openclaw/extensions/openclaw-weixin',
    'version': '2.4.3',
    'installedAt': '2026-05-18T09:32:00.000Z'
}

json.dump(d, open(p, 'w'), indent=2)
print('DONE')
