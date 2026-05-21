const fs = require('fs');
const p = '/home/admin/.openclaw/agents/main/agent/auth-profiles.json';
try {
  const raw = fs.readFileSync(p, 'utf-8');
  console.log('=== Raw file ===');
  console.log(raw);
  console.log('=== JSON parse test ===');
  const parsed = JSON.parse(raw);
  console.log(JSON.stringify(parsed, null, 2));
} catch(e) {
  console.log('Parse error:', e.message);
}
