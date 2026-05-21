const fs = require('fs');
const p = '/home/admin/.openclaw/agents/main/agent/models.json';
const m = JSON.parse(fs.readFileSync(p, 'utf-8'));
m.providers.deepseek.apiKey = '$api-key';
fs.writeFileSync(p, JSON.stringify(m, null, 2), 'utf-8');
const check = JSON.parse(fs.readFileSync(p, 'utf-8'));
console.log('deepseek apiKey:', check.providers.deepseek.apiKey);
