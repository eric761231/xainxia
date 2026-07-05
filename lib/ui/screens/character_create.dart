import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../models/char_create_template.dart';
import '../widgets/shared/game_message_dialog.dart';
import '../layout/char_create/char_create_ui_assets.dart';
import '../layout/char_create/char_create_ui_preloader.dart';
import '../layout/char_create/char_create_ui_spec.dart';
import '../layout/char_create/char_create_ui_dev_watcher.dart';
import '../widgets/char_create/char_create_back_button.dart';
import '../widgets/char_create/char_create_center_panel.dart';
import '../widgets/char_create/char_create_name_bar.dart';
import '../widgets/char_create/char_create_right_panel.dart';
import '../widgets/char_create/char_create_spirit_root_panel.dart';
import '../widgets/char_create/char_create_start_button.dart';
import '../widgets/char_create/char_create_text_styles.dart';

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
      if (_remainingPoints <= 0 || current >= base + CharCreateTemplate.bonusPool) return;
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

  Future<void> _fail(String message) => GameMessageDialog.show(
        context,
        title: '創角失敗',
        message: message,
      );

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = MediaQuery.paddingOf(context);
          final availableW =
              constraints.maxWidth - padding.left - padding.right;
          final availableH =
              constraints.maxHeight - padding.top - padding.bottom;
          CharCreateUiSpec.updateScaleFrom(Size(availableW, availableH));

          final leftWidth = CharCreateUiSpec.leftPanelWidthResolved;
          final rightWidth =
              CharCreateUiSpec.resolveRightPanelWidth(availableW);

          Widget buildLeftPanel() {
            return Padding(
              padding: EdgeInsets.only(
                top: CharCreateUiSpec.leftPanelTopOffset,
              ),
              child: FractionallySizedBox(
                heightFactor: CharCreateUiSpec.leftPanelHeightFraction,
                child: SizedBox(
                  width: leftWidth,
                  child: CharCreateSpiritRootPanel(
                    selectedIndex: _attribute,
                    enabled: enabled,
                    onSelected: (i) => setState(() => _attribute = i),
                  ),
                ),
              ),
            );
          }

          Widget buildRightPanel() {
            return Padding(
              padding: EdgeInsets.only(
                top: CharCreateUiSpec.rightPanelTopOffset,
              ),
              child: FractionallySizedBox(
                heightFactor: CharCreateUiSpec.rightPanelHeightFraction,
                child: CharCreateRightPanel(
                  width: rightWidth,
                  sex: _sex,
                  enabled: enabled,
                  remainingPoints: _remainingPoints,
                  statsIntel: _statsIntel,
                  statsSpirit: _statsSpirit,
                  statsAgility: _statsAgility,
                  statsConstitution: _statsConstitution,
                  onSexChanged: (v) => setState(() => _sex = v),
                  onAdjustStat: _adjustStat,
                  onResetStats: _resetStats,
                ),
              ),
            );
          }

          return Stack(
            children: [
              /* L1 全屏背景 */
              Positioned.fill(
                child: Image.asset(
                  CharCreateUiAssets.bg,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/loading.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: Color(0xFF140E0C)),
                  ),
                ),
              ),
              /* L2 中央立繪 */
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: CharCreateUiSpec.portraitStackWidthFactor,
                      heightFactor: CharCreateUiSpec.portraitStackHeightFactor,
                      child: CharCreateCenterPanel(sex: _sex),
                    ),
                  ),
                ),
              ),
              /* L3～L6：單一 SafeArea，scale 與桌面/手機一致 */
              SafeArea(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: CharCreateUiSpec.screenPaddingH,
                          vertical: CharCreateUiSpec.screenPaddingV,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: CharCreateUiSpec.screenLeftFlex,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: buildLeftPanel(),
                              ),
                            ),
                            Expanded(
                              flex: CharCreateUiSpec.screenCenterFlex,
                              child: const SizedBox.shrink(),
                            ),
                            Expanded(
                              flex: CharCreateUiSpec.screenRightFlex,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: buildRightPanel(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: CharCreateUiSpec.nameBarBottom,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(CharCreateUiSpec.nameBarOffsetH, 0),
                          child: CharCreateNameBar(
                            controller: _nameCtrl,
                            enabled: enabled,
                          ),
                        ),
                      ),
                    ),
                    CharCreateStartButton(submitting: _submitting, onTap: _submit),
                    CharCreateBackButton(enabled: enabled, onTap: _cancel),
                    if (kDebugMode)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Text(
                                'XML Live · scale ${CharCreateUiSpec.scale.toStringAsFixed(2)}',
                                style: CharCreateTextStyles.shadowLabel(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
