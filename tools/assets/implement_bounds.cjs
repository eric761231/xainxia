const fs=require('node:fs');
const edit=(p,f)=>fs.writeFileSync(p,f(fs.readFileSync(p,'utf8')));
for(const p of ['lib/ui/widgets/shared/tabbed_panel.dart','lib/ui/screens/decor_panel.dart','lib/ui/screens/gm_panel.dart']) {
 edit(p,s=>(p.includes('/screens/')?"import '../widgets/shared/panel_drag_bounds.dart';\n":"import 'panel_drag_bounds.dart';\n")+s.replace('Offset _offset = Offset.zero;', 'Offset _offset = Offset.zero;\n  final _contentKey = GlobalKey();')
 .replace('child: Container(\n','child: Container(\n        key: _contentKey,\n')
 .replace('child: Container(\r\n','child: Container(\r\n        key: _contentKey,\r\n')
 .replace('onPanUpdate: (d) => setState(() => _offset += d.delta),','onPanUpdate: (d) => setState(() => _offset = boundedPanelOffset(context, _contentKey, _offset, d.delta)),'));
}
edit('lib/ui/screens/game_hud_overlay.dart',s=>s.replace("import '../theme/game_design.dart';\n",''));
edit('lib/ui/screens/character_create.dart',s=>s.replace('icon: const Icon(Icons.remove), color: GameDesign.gold,',"icon: Text('−', style: GameDesign.text(size: 24, color: value > base ? GameDesign.gold : Colors.white54)), color: GameDesign.gold,").replace('icon: const Icon(Icons.add), color: GameDesign.gold,',"icon: Text('＋', style: GameDesign.text(size: 24, color: _remainingPoints > 0 ? GameDesign.gold : Colors.white54)), color: GameDesign.gold,"));
