const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
function files(dir = '.') {
  return fs.readdirSync(dir, {withFileTypes:true}).flatMap(entry => {
    if (entry.name.startsWith('.') || ['build','node_modules'].includes(entry.name)) return [];
    const file = path.posix.join(dir.replaceAll('\\','/'), entry.name);
    if (file.startsWith('docs/alpha/')) return [];
    return entry.isDirectory() ? files(file) : /\.(png|jpe?g|webp|svg|ico)$/i.test(file) ? [file] : [];
  });
}
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
if (require.main === module) process.stdout.write(JSON.stringify(Object.fromEntries(files().map(file=>[file,hash(file)]))));
module.exports = {files,hash};
