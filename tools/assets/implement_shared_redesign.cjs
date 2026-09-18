const fs=require('node:fs');
const edit=(p,f)=>fs.writeFileSync(p,f(fs.readFileSync(p,'utf8')));
edit('lib/ui/screens/account.dart',s=>"import '../theme/game_design.dart';\n"+s.replace('spec.box.height.clamp(40.0, 48.0)','spec.box.height.clamp(48.0, 56.0)').replace(/style: TextButton.styleFrom\([\s\S]*?padding: EdgeInsets.zero,\s*\),/,"style: GameDesign.button(primary: spec == AccountUiSpec.current.submit),"));
edit('lib/ui/screens/serverlist.dart',s=>s.replace('loginTextStyle(22)','loginTextStyle(spec.title.size)'));
edit('assets/ui/xaml/server_select.xaml',s=>s.replace('size="{fontTitle}"','size="24"'));
edit('assets/ui/xaml/theme.xaml',s=>s.replace('value="#F2EADA"','value="#FFFFFF"').replace('value="#74D2D5"','value="#89D5CC"').replace('value="#C9A24B"','value="#E8CE8B"').replace('value="#E8C86A"','value="#E8CE8B"'));
edit('lib/ui/widgets/shared/progress_overlay_scaffold.dart',s=>"import '../../theme/game_design.dart';\n"+s.replace(/final style = TextStyle\([\s\S]*?\n    \);/, 'final style = GameDesign.text(size: (s.messageSize * scale).clamp(18, 28));'));
edit('lib/ui/widgets/shared/energy_loading_bar.dart',s=>"import '../../theme/game_design.dart';\n"+s.replace('fontSize: spec.labelSize * scale,','fontSize: (spec.labelSize * scale).clamp(14, 18),\n                  fontFamily: GameDesign.text().fontFamily,').replace(/shadows: const \[\s*Shadow\(color: Color\(0xCC000000\), blurRadius: 3\),\s*\],/,'shadows: GameDesign.outline,').replace('final height = spec.barHeight * scale;', 'final height = (spec.barHeight * scale).clamp(24.0, 36.0);'));
