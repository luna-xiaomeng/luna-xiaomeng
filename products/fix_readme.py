import pathlib
p = pathlib.Path('README.md')
t = p.read_text('utf-8')

# Remove shared/ directory listing from Chinese section
old_ch = """| shared/             | 🔗 **共享配置** — 双端保持一致的SOUL/IDENTITY/MEMORY副本 | **自动同步** | 双端一致 |"""
new_ch = ""
t = t.replace(old_ch, new_ch)

# Remove shared/ from structure diagram (Chinese)
t = t.replace(
    "│   └── USER.md\n│   └── shared/\n",
    ""
)
t = t.replace(
    "├── shared/\n│   ├── CHANGELOG.md\n│   ├── IDENTITY.md\n│   ├── MEMORY.md\n│   ├── SOUL.md\n│   └── USER.md\n",
    ""
)

# Remove shared/ from English structure
t = t.replace(
    "│   └── shared/\n",
    ""
)

p.write_text(t, 'utf-8')
print('README fixed')
