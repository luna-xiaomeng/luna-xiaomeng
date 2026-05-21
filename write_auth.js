const fs = require('fs');
const p = '/home/admin/.openclaw/agents/main/agent/auth-profiles.json';

// Write it as proper valid JSON
const data = {
  "version": 1,
  "profiles": {
    "deepseek:default": {
      "type": "api_key",
      "provider": "deepseek",
      "key": "sk-e2ef86a0ff23458f9ac5f274cc95f7d4"
    },
    "modelstudio:default": {
      "type": "api_key",
      "provider": "modelstudio",
      "mode": "runtime"
    }
  }
};

// Backup old file
const bak = p + '.bak';
if (!fs.existsSync(bak)) {
  fs.copyFileSync(p, bak);
  console.log('Backup saved to:', bak);
}

fs.writeFileSync(p, JSON.stringify(data, null, 2), 'utf-8');
console.log('Written valid JSON auth-profiles.json');

// Verify
const check = JSON.parse(fs.readFileSync(p, 'utf-8'));
console.log('Verified ✓');
console.log('deepseek key present:', !!check.profiles['deepseek:default']);
console.log('deepseek key:', check.profiles['deepseek:default'].key.substring(0, 10) + '...');
