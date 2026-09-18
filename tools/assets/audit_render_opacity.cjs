const fs=require('fs');
const roots=['lib','assets/ui','assets/data'];
const hits=[];function scan(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=d+'/'+e.name;if(e.isDirectory()){scan(p);continue;}if(!/\.(dart|json|xaml|xml)$/.test(p))continue;fs.readFileSync(p,'utf8').split(/\r?\n/).forEach((line,index)=>{if(/opacity|alpha:|Opacity|BlendMode|ColorFilter|ShaderMask|saveLayer|FadeTransition/.test(line)&&!/^\s*(\/\/|\*|<!--)/.test(line))hits.push({path:p,line:index+1,code:line.trim(),role:/monster/.test(p)?'corpse fade (intentional)':/iso_object|my_game|world_scene|iso_map_component/.test(p)?'world placement/shadow (reviewed)':/character_create.dart|character_select.dart/.test(p)?'background overlay / buttons (portrait stays outside overlay)':'UI style/state or decorative effect; no global removal'});});}}
roots.forEach(scan);fs.writeFileSync('docs/alpha/render_opacity_inventory.json',JSON.stringify(hits,null,2));
const c=x=>'"'+String(x).replaceAll('"','""')+'"';fs.writeFileSync('docs/render_opacity_inventory.csv',['path,line,code,role',...hits.map(r=>Object.values(r).map(c).join(','))].join('\n'));
console.log('Opacity entries:',hits.length);
