const fs = require('fs');
const file = 'C:\\Users\\Administrator\\.openclaw\\agents\\main\\sessions\\084f6d32-22d1-49fe-a48c-a43b7bb67487.jsonl';
const content = fs.readFileSync(file, 'utf8');
const lines = content.split('\n');

let valid = 0, invalid = 0;
const issues = [];

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  if (line.trim().length === 0) {
    issues.push({line: i+1, issue: 'empty'});
    invalid++;
    continue;
  }
  try {
    JSON.parse(line);
    valid++;
  } catch(e) {
    invalid++;
    const posMatch = e.message.match(/position (\d+)/);
    if (posMatch) {
      const p = parseInt(posMatch[1]);
      const start = Math.max(0, p-40);
      const end = Math.min(line.length, p+40);
      const around = line.substring(start, end);
      issues.push({line: i+1, issue: e.message.substring(0, 60), pos: p, around});
    } else {
      issues.push({line: i+1, issue: e.message.substring(0, 80)});
    }
  }
}

console.log('Summary:');
console.log('  Total lines: ' + lines.length);
console.log('  Valid JSON: ' + valid);
console.log('  Invalid: ' + invalid);

if (issues.length > 0) {
  console.log('\nIssues (' + issues.length + ' total, showing first 10):');
  for (const iss of issues.slice(0, 10)) {
    console.log('  Line ' + iss.line + ': ' + iss.issue);
    if (iss.around) {
      console.log('    Context: ...' + iss.around + '...');
    }
  }
  
  // Check if all invalid are trailing/empty
  const emptyIssues = issues.filter(i => i.issue === 'empty');
  const lastValidLine = lines.map((l, idx) => { try { JSON.parse(l); return idx; } catch(e) { return -1; } }).filter(i => i >= 0);
  const maxValidLineNum = lastValidLine.length > 0 ? Math.max(...lastValidLine) : -1;
  const trailingIssues = issues.filter(i => i.line - 1 > maxValidLineNum);
  
  console.log('\nEmpty lines: ' + emptyIssues.length);
  console.log('Trailing after last valid JSON: ' + trailingIssues.length);
  console.log('Last valid JSON line: ' + (maxValidLineNum + 1));
  
  if (emptyIssues.length + trailingIssues.length === issues.length) {
    console.log('\n✅ All issues are trailing/empty - safe truncation');
  } else {
    const midIssues = issues.filter(i => i.line - 1 <= maxValidLineNum && i.issue !== 'empty');
    console.log('\n⚠️ ' + midIssues.length + ' issues in the middle of the file');
    for (const iss of midIssues) {
      console.log('  ** Line ' + iss.line + ': ' + iss.issue);
      if (iss.around) console.log('     ' + iss.around);
    }
  }
}
