// One-time migration: preserve screen state/network methods, replace presentation.
const fs = require('node:fs');
const p = 'lib/ui/screens/character_create.dart';
let s = fs.readFileSync(p, 'utf8');
s = s.replace("import 'package:flutter/foundation.dart';", "import '../theme/game_design.dart';\nimport '../widgets/shared/character_stage.dart';");
for (const name of ['back_button','center_panel','name_bar','right_panel','start_button','text_styles']) {
  s=s.replace(new RegExp("import '../widgets/char_create/char_create_"+name+".dart';\\r?\\n"),'');
}
s=s.replace(/import '..\/layout\/char_create\/char_create_ui_assets.dart';\r?\n/,'');
const start=s.indexOf('  Widget _buildBody(BuildContext context) {');
if(start<0) throw Error('create presentation not found');
s=s.slice(0,start)+`  Widget _buildBody(BuildContext context) {
    final enabled = !_submitting;
    return Scaffold(body: CharacterStage(
      sex: _sex, onBack: enabled ? _cancel : null,
      left: CharCreateSpiritRootPanel(selectedIndex: _attribute, enabled: enabled,
        onSelected: (i) => setState(() => _attribute = i)),
      right: Column(children: [
        const StageHeading('屬性分配'),
        _stat('神識', 'spirit', _statsSpirit, CharCreateTemplate.baseSpirit),
        _stat('體魄', 'constitution', _statsConstitution, CharCreateTemplate.baseConstitution),
        _stat('敏捷', 'agility', _statsAgility, CharCreateTemplate.baseAgility),
        _stat('悟性', 'intel', _statsIntel, CharCreateTemplate.baseIntel),
        const SizedBox(height: 20),
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12, children: [
            Text('剩餘點數  $_remainingPoints', style: GameDesign.text(size: 20, color: GameDesign.gold)),
            GameAction('重置', onPressed: enabled ? _resetStats : null),
          ]),
      ]),
      footer: LayoutBuilder(builder: (context, constraints) {
        final controls = <Widget>[
          Row(mainAxisSize: MainAxisSize.min, children: [for (var sex = 0; sex < 2; sex++)
            Semantics(selected: _sex == sex, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GameAction(sex == 0 ? '男' : '女', primary: _sex == sex,
                onPressed: enabled ? () => setState(() => _sex = sex) : null))),
          ]),
          SizedBox(width: constraints.maxWidth < 400 ? constraints.maxWidth : 340,
            child: TextField(controller: _nameCtrl, enabled: enabled,
              style: GameDesign.text(size: 18), maxLength: 12,
              decoration: InputDecoration(labelText: '修士名號', hintText: '請輸入名號',
                counterText: '', labelStyle: GameDesign.text(), hintStyle: GameDesign.text(),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: GameDesign.jade)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: GameDesign.gold, width: 2))),
              onSubmitted: (_) => _submit())),
          GameAction(_submitting ? '建立中…' : '進入遊戲', primary: true,
            onPressed: enabled ? _submit : null),
        ];
        return Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 32, runSpacing: 16, children: controls);
      }),
    ));
  }

  Widget _stat(String label, String key, int value, int base) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: GameDesign.text(size: 22))),
      IconButton(key: ValueKey('minus-$key'), tooltip: '減少$label',
        onPressed: !_submitting && value > base ? () => _adjustStat(key, -1) : null,
        icon: const Icon(Icons.remove), color: GameDesign.gold,
        disabledColor: Colors.white38),
      SizedBox(width: 38, child: Text('$value', textAlign: TextAlign.center, style: GameDesign.text(size: 22))),
      IconButton(key: ValueKey('plus-$key'), tooltip: '增加$label',
        onPressed: !_submitting && _remainingPoints > 0 ? () => _adjustStat(key, 1) : null,
        icon: const Icon(Icons.add), color: GameDesign.gold, disabledColor: Colors.white38),
    ]),
  );
}
`;
fs.writeFileSync(p,s);
