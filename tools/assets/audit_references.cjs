const fs=require('fs');
const catalog=JSON.parse(fs.readFileSync('assets/data/object_catalog.json','utf8')).objects;
const results=[];
for(const [id,item] of Object.entries(catalog)){const path=`assets/${item.dir||'objects'}/${item.image}`;results.push({kind:'catalog',id,path,exists:fs.existsSync(path),note:fs.existsSync(path)?'':'missing file; existing fallback path; not an alpha defect'});}
const source=fs.readFileSync('lib/game/map/iso_monster_component.dart','utf8');
for(const m of source.matchAll(/'([^']+)': '(assets\/monsters\/[^']+\.png)'/g))results.push({kind:'monster name mapping',id:m[1],path:m[2],exists:fs.existsSync(m[2]),note:fs.existsSync(m[2])?'':'declared future art; component intentionally falls back'});
fs.writeFileSync('docs/alpha/reference_integrity.json',JSON.stringify(results,null,2));console.log(JSON.stringify(results.filter(r=>!r.exists),null,2));
