const fs = require('node:fs');
const {hash} = require('./hash_assets.cjs');
const check = process.argv.includes('--check');
const constants = 'lib/ui/layout/char_create/char_create_ui_assets.dart';
let code = fs.readFileSync(constants, 'utf8');
const manifest = [];
for (const name of ['char_bg','char_male','char_female']) {
  const source = `assets/ui/char_create/${name}.png`;
  const sha256 = hash(source);
  const published = `assets/ui/char_create/${name}_${sha256.slice(0,8)}.png`;
  if (check) {
    if (!fs.existsSync(published) || hash(published)!==sha256 || !code.includes(published)) throw Error(`Stale published asset: ${source}`);
  } else {
    fs.copyFileSync(source,published);
    code=code.replace(new RegExp(`assets/ui/char_create/${name}_[0-9a-f]{8}\\.png`,'g'),published);
  }
  manifest.push({source,published,sha256});
}
if (!check) {
  fs.writeFileSync(constants,code);
  fs.writeFileSync('docs/alpha/published_assets.json',JSON.stringify(manifest,null,2)+'\n');
}
console.log(check?'Published assets match sources':JSON.stringify(manifest,null,2));
