import '../theme/game_design.dart';
import '../widgets/shared/character_stage.dart';
import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../models/char_create_template.dart';
import '../widgets/shared/game_message_dialog.dart';
import '../layout/char_create/char_create_ui_preloader.dart';
import '../layout/char_create/char_create_ui_spec.dart';
import '../layout/char_create/char_create_ui_dev_watcher.dart';
import '../widgets/char_create/char_create_spirit_root_panel.dart';

/*
 * 創角全屏 Overlay
 * 六層 Stack：背景、中央立繪、左右欄、名稱列、開始、返回
 */
class CharacterCreateOverlay extends StatefulWidget {
  const CharacterCreateOverlay(this.game, {super.key});

  final MyGame game;

  @override
  State<CharacterCreateOverlay> createState() => _CharacterCreateOverlayState();
}

class _CharacterCreateOverlayState extends State<CharacterCreateOverlay> {
  final TextEditingController _nameCtrl = TextEditingController();
  int _sex = 0;
  int _attribute = 0;
  int _statsIntel = CharCreateTemplate.baseIntel;
  int _statsSpirit = CharCreateTemplate.baseSpirit;
  int _statsAgility = CharCreateTemplate.baseAgility;
  int _statsConstitution = CharCreateTemplate.baseConstitution;
  int _remainingPoints = CharCreateTemplate.bonusPool;
  bool _submitting = false;
  bool _layoutReady = false;

  @override
  void initState() {
    super.initState();
    if (CharCreateUiPreloader.isDone || CharCreateUiSpec.isLoaded) {
      _layoutReady = true;
      CharCreateUiDevWatcher.ensureStarted();
      return;
    }
    CharCreateUiSpec.ensureLoaded().then((_) {
      if (mounted) setState(() => _layoutReady = true);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _resetStats() {
    setState(() {
      _statsIntel = CharCreateTemplate.baseIntel;
      _statsSpirit = CharCreateTemplate.baseSpirit;
      _statsAgility = CharCreateTemplate.baseAgility;
      _statsConstitution = CharCreateTemplate.baseConstitution;
      _remainingPoints = CharCreateTemplate.bonusPool;
    });
  }

  void _adjustStat(String stat, int delta) {
    final (current0, base) = switch (stat) {
      'intel' => (_statsIntel, CharCreateTemplate.baseIntel),
      'spirit' => (_statsSpirit, CharCreateTemplate.baseSpirit),
      'agility' => (_statsAgility, CharCreateTemplate.baseAgility),
      _ => (_statsConstitution, CharCreateTemplate.baseConstitution),
    };
    var current = current0;
    if (delta > 0) {
      if (_remainingPoints <= 0 ||
          current >= base + CharCreateTemplate.bonusPool) {
        return;
      }
      current++;
      _remainingPoints--;
    } else {
      if (current <= base) return;
      current--;
      _remainingPoints++;
    }
    setState(() {
      switch (stat) {
        case 'intel':
          _statsIntel = current;
        case 'spirit':
          _statsSpirit = current;
        case 'agility':
          _statsAgility = current;
        default:
          _statsConstitution = current;
      }
    });
  }

  Future<void> _fail(String message) =>
      GameMessageDialog.show(context, title: '創角失敗', message: message);

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    if (name.length < 2 || name.length > 12) {
      await _fail('角色名稱需 2～12 字');
      return;
    }
    if (_remainingPoints != 0) {
      await _fail('請分配完 $_remainingPoints 點剩餘屬性點');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await widget.game.createCharacter(
        name: name,
        sex: _sex,
        attribute: _attribute,
        statsIntel: _statsIntel,
        statsSpirit: _statsSpirit,
        statsAgility: _statsAgility,
        statsConstitution: _statsConstitution,
      );
      if (!mounted) return;
      if (result.success) {
        widget.game.showCharacterSelect();
        return;
      }
      await _fail(result.message);
    } catch (_) {
      if (mounted) await _fail('連線異常，請稍後再試');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _cancel() => widget.game.showCharacterSelect();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CharCreateUiSpec.revision,
      builder: (context, child) {
        if (!_layoutReady) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return _buildBody(context);
      },
    );
  }

  Widget _buildBody(BuildContext context) {
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
        icon: Text('−', style: GameDesign.text(size: 24, color: value > base ? GameDesign.gold : Colors.white54)), color: GameDesign.gold,
        disabledColor: Colors.white38),
      SizedBox(width: 38, child: Text('$value', textAlign: TextAlign.center, style: GameDesign.text(size: 22))),
      IconButton(key: ValueKey('plus-$key'), tooltip: '增加$label',
        onPressed: !_submitting && _remainingPoints > 0 ? () => _adjustStat(key, 1) : null,
        icon: Text('＋', style: GameDesign.text(size: 24, color: _remainingPoints > 0 ? GameDesign.gold : Colors.white54)), color: GameDesign.gold, disabledColor: Colors.white38),
    ]),
  );
}
