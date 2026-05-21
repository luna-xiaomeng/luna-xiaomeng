const fs = require('fs');
const p = '/home/admin/.openclaw/agents/main/agent/auth-profiles.json';
const raw = fs.readFileSync(p, 'utf-8');

// Check if it's valid JSON
try {
  JSON.parse(raw);
  console.log('Valid JSON ✓');
} catch(e) {
  console.log('NOT valid JSON:', e.message);
}

// Check what Node's require gives us (lenient parser?)
try {
  const f = require(p);
  console.log('require() result:', JSON.stringify(f));
} catch(e) {
  console.log('require() fail:', e.message);
}

// Try to fix it: quote all unquoted keys
// Simple approach: wrap unquoted property names
const fixed = raw
  .replace(/(\s+)(\w[\w:]*)(\s*:)/g, '$1"$2"$3')
  .replace(/:\s+(\w[\w]*)/g, function(m) {
    const val = m.trim().slice(1).trim();
    if (val === 'true' || val === 'false' || val === 'null' || !isNaN(Number(val))) {
      return ': ' + val;
    }
    return ': "' + val + '"';
  });
  
try {
  const p2 = JSON.parse(fixed);
  console.log('Fixed JSON ✓');
  console.log(JSON.stringify(p2, null, 2));
} catch(e) {
  console.log('Fix attempt failed:', e.message);
}
