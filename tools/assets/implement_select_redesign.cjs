const fs=require('node:fs');
const p='lib/ui/screens/character_select.dart';
let s=fs.readFileSync(p,'utf8');
for(const line of s.split('\n')) {
 if(line.startsWith('import ') && !['flutter/material','my_game','models/game_character','game_message_dialog','char_select_ui_spec','char_create_ui_spec','game_ui_styles'].some(x=>line.includes(x))) s=s.replace(line+'\n','');
}
s="import '../theme/game_design.dart';\nimport '../widgets/shared/character_stage.dart';\nimport '../../models/char_create_template.dart';\n"+s;
const a=s.indexOf('    final confirmed = await showDialog<bool>('),b=s.indexOf('    if (confirmed != true',a);
s=s.slice(0,a)+`    final confirmed = await GameMessageDialog.confirm(context,
      title: '刪除角色', message: '確定要永久刪除角色「\${char.name}」？\\n此操作無法復原。',
      confirmLabel: '刪除', danger: true);
`+s.slice(b);
const start=s.indexOf('  Widget _buildScreen(BuildContext context) {');
s=s.slice(0,start)+`  Widget _buildScreen(BuildContext context) {
    final chars = _characters;
    final selected = _selected;
    return Scaffold(body: CharacterStage(
      sex: selected?.sex, onBack: _entering ? null : _logoutAccount,
      left: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const StageHeading('角色列表'),
        Text('\${_summary?.count ?? 0} / \${_summary?.maxSlots ?? 4}',
          textAlign: TextAlign.center, style: GameDesign.text(color: GameDesign.gold)),
        const SizedBox(height: 16),
        if(chars.isEmpty) Text('尚無角色', textAlign: TextAlign.center, style: GameDesign.text(size: 22)),
        for(var i=0;i<chars.length;i++) Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(selected: i == _selectedIndex,
            child: TextButton(onPressed: _entering ? null : () => setState(() => _selectedIndex=i),
              style: GameDesign.button(primary: i == _selectedIndex),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [
                  Text(chars[i].name, style: GameDesign.text(size: 22)),
                  const SizedBox(height: 8),
                  Text('\${chars[i].realm} · Lv.\${chars[i].level}', style: GameDesign.text()),
                ]))))),
      ]),
      right: selected == null ? const SizedBox.shrink() : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const StageHeading('修士資訊'),
          Text(selected.name, textAlign: TextAlign.center,
            style: GameDesign.text(size: 24, color: GameDesign.gold)),
          const SizedBox(height: 16),
          for(final row in <(String, String)>[
            ('靈根', CharCreateTemplate.attributeNames[selected.attribute.clamp(0, 7)]),
            ('境界', '\${selected.realm} · Lv.\${selected.level}'),
            ('生命', '\${selected.hp} / \${selected.hpMax}'),
            ('法力', '\${selected.mp} / \${selected.mpMax}'),
            ('修為', '\${selected.exp} / \${selected.expMax}'),
            ('神識', '\${selected.statsSpirit}'), ('體魄', '\${selected.statsConstitution}'),
            ('敏捷', '\${selected.statsAgility}'), ('悟性', '\${selected.statsIntel}'),
            ('攻擊', '\${selected.attack}'), ('防禦', '\${selected.defense}'),
            ('命中', '\${selected.hit}'), ('閃避', '\${selected.dodge}'),
            ('傀儡上限', '\${selected.puppetMax}'),
            ('法術領悟', '\${selected.spellLearnRate}%'), ('製作熟練', '\${selected.craftProficiencyRate}%'),
            ('本命武器', selected.natalWeapon.isEmpty ? '未裝備' : selected.natalWeapon),
            ('核心功法', selected.coreTechnique.isEmpty ? '未習得' : selected.coreTechnique),
            ('勢力', selected.faction.isEmpty ? '無' : selected.faction),
            ('生活職業', selected.lifeJob.isEmpty ? '無' : '\${selected.lifeJob} Lv.\${selected.lifeJobLevel}'),
          ]) Padding(padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row.$1, style: GameDesign.text()), const SizedBox(width: 12),
              Expanded(child: Text(row.$2, textAlign: TextAlign.right,
                style: GameDesign.text(color: GameDesign.muted))),
            ])),
        ]),
      footer: Wrap(alignment: WrapAlignment.center, spacing: 24, runSpacing: 12, children: [
        GameAction('建立角色', onPressed: !_entering && (_summary?.canCreateMore ?? true) ? _openCreate : null),
        GameAction(_entering ? '進入中…' : '進入遊戲', primary: true,
          onPressed: !_entering && selected != null ? _enterGame : null),
        GameAction('刪除角色', danger: true,
          onPressed: !_entering && selected != null ? _deleteCharacter : null),
      ]),
    ));
  }
}
`;
fs.writeFileSync(p,s);
