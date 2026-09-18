import '../theme/game_design.dart';
import '../widgets/shared/character_stage.dart';
import '../../models/char_create_template.dart';
import 'package:flutter/material.dart';
import '../../game/my_game.dart';
import '../../models/game_character.dart';
import '../widgets/shared/game_message_dialog.dart';
import '../layout/char_select/char_select_ui_spec.dart';
import '../layout/char_create/char_create_ui_spec.dart';
import '../theme/game_ui_styles.dart';

/// 角色選擇全屏 Overlay（三欄布局）。
class CharacterSelectOverlay extends StatefulWidget {
  const CharacterSelectOverlay(this.game, {super.key});

  final MyGame game;

  @override
  State<CharacterSelectOverlay> createState() => _CharacterSelectOverlayState();
}

class _CharacterSelectOverlayState extends State<CharacterSelectOverlay> {
  bool _layoutReady = false;
  bool _entering = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (CharSelectUiSpec.isLoaded && CharCreateUiSpec.isLoaded) {
      _layoutReady = true;
      return;
    }
    Future.wait([
      CharSelectUiSpec.ensureLoaded(),
      CharCreateUiSpec.ensureLoaded(),
    ]).then((_) {
      if (mounted) setState(() => _layoutReady = true);
    });
  }

  List<GameCharacter> get _characters =>
      widget.game.characterService?.cachedSummary?.characters ??
      const <GameCharacter>[];

  CharacterListSummary? get _summary =>
      widget.game.characterService?.cachedSummary;

  GameCharacter? get _selected {
    final chars = _characters;
    if (chars.isEmpty) return null;
    return chars[_selectedIndex.clamp(0, chars.length - 1)];
  }

  Future<void> _enterGame() async {
    final char = _selected;
    if (char == null || _entering) return;
    setState(() => _entering = true);
    try {
      await widget.game.enterWorldWithCharacter(char.name);
    } catch (e) {
      if (mounted) {
        await GameMessageDialog.show(
          context,
          title: '進入失敗',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  void _openCreate() => widget.game.showCharacterCreate();

  Future<void> _deleteCharacter() async {
    final char = _selected;
    if (char == null || _entering) return;

    final confirmed = await GameMessageDialog.confirm(context,
      title: '刪除角色', message: '確定要永久刪除角色「${char.name}」？\n此操作無法復原。',
      confirmLabel: '刪除', danger: true);
    if (confirmed != true || !mounted) return;

    setState(() => _entering = true);
    try {
      final result = await widget.game.deleteCharacter(char.name);
      if (!mounted) return;

      if (result.success) {
        final remaining = _characters;
        if (remaining.isEmpty) {
          widget.game.showCharacterCreate();
        } else {
          setState(() {
            _selectedIndex = 0;
          });
        }
      } else {
        await GameMessageDialog.show(
          context,
          title: '刪除失敗',
          message: result.message,
        );
      }
    } catch (e) {
      if (mounted) {
        await GameMessageDialog.show(
          context,
          title: '刪除失敗',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  Future<void> _logoutAccount() async {
    if (_entering) return;
    await widget.game.logoutToAccount();
  }

  @override
  Widget build(BuildContext context) {
    if (!_layoutReady) {
      return Material(
        color: Colors.black54,
        child: Center(
          child: Text(
            '載入中…',
            style: GameUiStyles.shadowTextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: CharSelectUiSpec.revision,
      builder: (context, _, child) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final chars = _characters;
    final selected = _selected;
    return Scaffold(body: CharacterStage(
      sex: selected?.sex, onBack: _entering ? null : _logoutAccount,
      left: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const StageHeading('角色列表'),
        Text('${_summary?.count ?? 0} / ${_summary?.maxSlots ?? 4}',
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
                  Text('${chars[i].realm} · Lv.${chars[i].level}', style: GameDesign.text()),
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
            ('境界', '${selected.realm} · Lv.${selected.level}'),
            ('生命', '${selected.hp} / ${selected.hpMax}'),
            ('法力', '${selected.mp} / ${selected.mpMax}'),
            ('修為', '${selected.exp} / ${selected.expMax}'),
            ('神識', '${selected.statsSpirit}'), ('體魄', '${selected.statsConstitution}'),
            ('敏捷', '${selected.statsAgility}'), ('悟性', '${selected.statsIntel}'),
            ('攻擊', '${selected.attack}'), ('防禦', '${selected.defense}'),
            ('命中', '${selected.hit}'), ('閃避', '${selected.dodge}'),
            ('傀儡上限', '${selected.puppetMax}'),
            ('法術領悟', '${selected.spellLearnRate}%'), ('製作熟練', '${selected.craftProficiencyRate}%'),
            ('本命武器', selected.natalWeapon.isEmpty ? '未裝備' : selected.natalWeapon),
            ('核心功法', selected.coreTechnique.isEmpty ? '未習得' : selected.coreTechnique),
            ('勢力', selected.faction.isEmpty ? '無' : selected.faction),
            ('生活職業', selected.lifeJob.isEmpty ? '無' : '${selected.lifeJob} Lv.${selected.lifeJobLevel}'),
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
