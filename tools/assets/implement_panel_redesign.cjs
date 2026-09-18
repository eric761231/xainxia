const fs=require('node:fs');
const edit=(p,f)=>fs.writeFileSync(p,f(fs.readFileSync(p,'utf8')));
edit('lib/ui/widgets/char_create/char_create_spirit_root_panel.dart',s=>s.replace('vertical: 8','vertical: 6').replace('width: 58, height: 58','width: 50, height: 50'));
for(const p of ['lib/ui/widgets/shared/tabbed_panel.dart','lib/ui/screens/decor_panel.dart','lib/ui/screens/gm_panel.dart']) {
 edit(p,s=>s.replace(/height: 34,/g,'height: 48,').replace(/height: 30,/g,'height: 44,')
   .replace(/child: const Icon\(Icons.close, size: 16, color: ([^)]+)\),/g,'child: SizedBox(width: 44, height: 44, child: Icon(Icons.close, size: 20, color: $1)),')
   .replace('padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),','constraints: const BoxConstraints(minWidth: 44, minHeight: 44),\n      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),'));
}
edit('lib/ui/widgets/shared/context_menu.dart',s=>s.replace('_width = 132.0','_width = 168.0').replace('_itemH = 34.0','_itemH = 44.0').replace('_titleH = 28.0','_titleH = 36.0'));
edit('lib/ui/screens/game_hud_overlay.dart',s=>s.replace('            // 依視窗等比例縮放',`            if (constraints.maxWidth < 1600 || constraints.maxHeight < 900) {
              return _CompactHud(game);
            }
            // 依視窗等比例縮放`).replace('Transform.scale(scale: scale, alignment: alignment, child: child)','Transform.scale(scale: scale.clamp(1.0, 1.4), alignment: alignment, child: child)').replace('Color(0xFF0B0A08)','Color(0xEE152629)'));
