// Local-only static preview with no-store headers; no deployment or API proxy.
const http=require('node:http'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(process.argv[2]||'build/web');
const build=path.resolve('build')+path.sep;
if(!root.startsWith(build))throw Error('Preview root must be inside build/');
const port=Number(process.argv[3]||3000);
const mime={'.html':'text/html','.js':'application/javascript','.json':'application/json','.png':'image/png','.wasm':'application/wasm','.ttf':'font/ttf','.xml':'application/xml','.xaml':'application/xml'};
http.createServer((req,res)=>{let file;try{const url=new URL(req.url,'http://127.0.0.1');file=path.resolve(root,'.'+decodeURIComponent(url.pathname==='/'?'/index.html':url.pathname));}catch{res.writeHead(400);res.end();return;}
if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);res.end();return;}res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});res.end(data);});
}).listen(port,'127.0.0.1',()=>console.log(`Preview ${root} at http://127.0.0.1:${port}`));
