import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/my_game.dart';
import '../../models/game_character.dart';
import '../widgets/shared/game_message_dialog.dart';
import '../theme/game_ui_fonts.dart';
import '../layout/char_select/char_select_ui_spec.dart';
import '../widgets/char_create/char_create_cloud_label.dart';
import '../widgets/char_select/char_select_char_card.dart';
import '../widgets/char_select/char_select_center_panel.dart';
import '../widgets/char_select/char_select_info_panel.dart';
import '../layout/char_create/char_create_ui_assets.dart';

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
    if (CharSelectUiSpec.isLoaded) {
      _layoutReady = true;
      return;
    }
    CharSelectUiSpec.ensureLoaded().then((_) {
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除角色'),
        content: Text('確定要永久刪除角色「${char.name}」？\n此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
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
      return const Material(
        color: Colors.black54,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: CharSelectUiSpec.revision,
      builder: (context, _, child) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final chars = _characters;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xCC000000),
        systemNavigationBarColor: Color(0xCC000000),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            CharSelectUiSpec.updateScaleFrom(size);

            return Stack(
              fit: StackFit.expand,
              children: [
                // L1 背景
                Image.asset(CharCreateUiAssets.bg, fit: BoxFit.cover),
                // L2 暗色蒙版
                ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                // L3 UI
                SafeArea(child: _buildLayout(context, chars)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, List<GameCharacter> chars) {
    return Column(
      children: [
        _TopBar(summary: _summary, entering: _entering, onBack: _logoutAccount),
        Expanded(
          child: chars.isEmpty
              ? _EmptyState(
                  canCreate: _summary?.canCreateMore ?? true,
                  onCreate: _openCreate,
                )
              : _ThreePanelContent(
                  characters: chars,
                  selectedIndex: _selectedIndex.clamp(0, chars.length - 1),
                  entering: _entering,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                  onOpenCreate: _openCreate,
                  canCreate: _summary?.canCreateMore ?? true,
                ),
        ),
        _BottomBar(
          hasSelection: _selected != null,
          entering: _entering,
          canCreate: _summary?.canCreateMore ?? true,
          onEnter: _enterGame,
          onCreate: _openCreate,
          onDelete: _deleteCharacter,
        ),
      ],
    );
  }
}

// ── 頂部欄 ─────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.summary,
    required this.entering,
    required this.onBack,
  });

  final CharacterListSummary? summary;
  final bool entering;
  final VoidCallback onBack;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _backHovered = false;
  bool _backPressed = false;

  @override
  Widget build(BuildContext context) {
    final slotText = widget.summary != null
        ? '${widget.summary!.count}/${widget.summary!.maxSlots}'
        : '';

    Color? backOverlay;
    if (_backPressed) {
      backOverlay = CharSelectUiSpec.backBtnPressedOverlay;
    } else if (_backHovered) {
      backOverlay = CharSelectUiSpec.backBtnHoverOverlay;
    }

    return SizedBox(
      height: CharSelectUiSpec.topBarHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: CharSelectUiSpec.topBarPaddingH,
          vertical: CharSelectUiSpec.topBarPaddingV,
        ),
        child: Row(
          children: [
            // 返回按鈕
            MouseRegion(
              onEnter: (_) => setState(() => _backHovered = true),
              onExit: (_) =>
                  setState(() => _backHovered = _backPressed = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.entering ? null : widget.onBack,
                onTapDown: (_) => setState(() => _backPressed = true),
                onTapUp: (_) => setState(() => _backPressed = false),
                onTapCancel: () => setState(() => _backPressed = false),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      CharCreateCloudLabel(
                        height: CharSelectUiSpec.topBarBackBtnHeight,
                        width: CharSelectUiSpec.topBarBackBtnWidth,
                        asset: CharCreateUiAssets.cloudLabel04,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              _backHovered
                                  ? CharCreateUiAssets.backIconHover
                                  : CharCreateUiAssets.backIcon,
                              width: CharSelectUiSpec.topBarBackIconSize,
                              height: CharSelectUiSpec.topBarBackIconSize,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '返回',
                              style: TextStyle(
                                fontSize:
                                    CharSelectUiSpec.topBarBackLabelFontSize,
                                fontFamily: GameUiFonts.kingHwaOldSong,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (backOverlay != null)
                        Positioned.fill(child: ColoredBox(color: backOverlay)),
                    ],
                  ),
                ),
              ),
            ),
            // 標題（置中）
            Expanded(
              child: Center(
                child: Text(
                  '角色列表',
                  style: TextStyle(
                    color: Color(CharSelectUiSpec.colorTitle),
                    fontSize: CharSelectUiSpec.topBarTitleFontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: GameUiFonts.kingHwaOldSong,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Color(0xCC000000),
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 槽位計數
            SizedBox(
              width: CharSelectUiSpec.topBarBackBtnWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  slotText,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: CharSelectUiSpec.topBarSlotFontSize,
                    fontFamily: GameUiFonts.kingHwaOldSong,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 三欄主內容 ─────────────────────────────────────────────────

class _ThreePanelContent extends StatelessWidget {
  const _ThreePanelContent({
    required this.characters,
    required this.selectedIndex,
    required this.entering,
    required this.onSelect,
    required this.onOpenCreate,
    required this.canCreate,
  });

  final List<GameCharacter> characters;
  final int selectedIndex;
  final bool entering;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenCreate;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftW = CharSelectUiSpec.leftPanelWidthResolved;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左欄：角色列表
            SizedBox(
              width: leftW,
              child: _LeftPanel(
                characters: characters,
                selectedIndex: selectedIndex,
                entering: entering,
                onSelect: onSelect,
              ),
            ),
            // 中央：立繪
            Expanded(
              child: characters.isNotEmpty
                  ? CharSelectCenterPanel(character: characters[selectedIndex])
                  : const SizedBox.shrink(),
            ),
            // 右欄：資訊欄
            SizedBox(
              width: CharSelectUiSpec.resolveRightPanelWidth(
                constraints.maxWidth,
              ),
              child: characters.isNotEmpty
                  ? CharSelectInfoPanel(character: characters[selectedIndex])
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

// ── 左欄（列表）─────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.characters,
    required this.selectedIndex,
    required this.entering,
    required this.onSelect,
  });

  final List<GameCharacter> characters;
  final int selectedIndex;
  final bool entering;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: CharSelectUiSpec.leftPanelPaddingH,
        right: CharSelectUiSpec.leftPanelPaddingH,
        top: CharSelectUiSpec.leftPanelTopOffset,
      ),
      child: ListView.separated(
        itemCount: characters.length,
        separatorBuilder: (_, i) =>
            SizedBox(height: CharSelectUiSpec.leftPanelListSpacing),
        itemBuilder: (_, i) => CharSelectCharCard(
          character: characters[i],
          isSelected: i == selectedIndex,
          enabled: !entering,
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}

// ── 底部按鈕列 ─────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.hasSelection,
    required this.entering,
    required this.canCreate,
    required this.onEnter,
    required this.onCreate,
    required this.onDelete,
  });

  final bool hasSelection;
  final bool entering;
  final bool canCreate;
  final Future<void> Function() onEnter;
  final VoidCallback onCreate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CharSelectUiSpec.bottomBarHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: CharSelectUiSpec.bottomBarPaddingH,
          vertical: CharSelectUiSpec.bottomBarPaddingV,
        ),
        child: Row(
          children: [
            // 建立角色
            _BottomBtn(
              label: '＋ 建立角色',
              width: CharSelectUiSpec.bottomBarSideBtnWidth,
              height: CharSelectUiSpec.bottomBarBtnHeight,
              fontSize: CharSelectUiSpec.bottomBarFontSize,
              enabled: canCreate && !entering,
              hoverColor: CharSelectUiSpec.createBtnHoverOverlay,
              pressedColor: CharSelectUiSpec.createBtnPressedOverlay,
              bgColor: Colors.white.withValues(alpha: 0.12),
              onTap: onCreate,
            ),
            const Spacer(),
            // 進入遊戲（居中，主要按鈕）
            _BottomBtn(
              label: entering ? '進入中…' : '進入遊戲',
              width: CharSelectUiSpec.bottomBarEnterBtnWidth,
              height: CharSelectUiSpec.bottomBarBtnHeight,
              fontSize: CharSelectUiSpec.bottomBarFontSize,
              enabled: hasSelection && !entering,
              hoverColor: CharSelectUiSpec.enterBtnHoverOverlay,
              pressedColor: CharSelectUiSpec.enterBtnPressedOverlay,
              bgColor: Color(
                CharSelectUiSpec.colorAccent,
              ).withValues(alpha: 0.20),
              borderColor: Color(
                CharSelectUiSpec.colorAccent,
              ).withValues(alpha: 0.60),
              textColor: Color(CharSelectUiSpec.colorAccent),
              onTap: onEnter,
            ),
            const Spacer(),
            // 刪除角色（右側，危險色）
            _BottomBtn(
              label: '刪除角色',
              width: CharSelectUiSpec.bottomBarSideBtnWidth,
              height: CharSelectUiSpec.bottomBarBtnHeight,
              fontSize: CharSelectUiSpec.bottomBarFontSize,
              enabled: hasSelection && !entering,
              hoverColor: CharSelectUiSpec.deleteBtnHoverOverlay,
              pressedColor: CharSelectUiSpec.deleteBtnPressedOverlay,
              bgColor: Color(
                CharSelectUiSpec.colorDanger,
              ).withValues(alpha: 0.15),
              borderColor: Color(
                CharSelectUiSpec.colorDanger,
              ).withValues(alpha: 0.50),
              textColor: Color(CharSelectUiSpec.colorDanger),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBtn extends StatefulWidget {
  const _BottomBtn({
    required this.label,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.enabled,
    required this.hoverColor,
    required this.pressedColor,
    required this.bgColor,
    required this.onTap,
    this.borderColor,
    this.textColor,
  });

  final String label;
  final double width;
  final double height;
  final double fontSize;
  final bool enabled;
  final Color hoverColor;
  final Color pressedColor;
  final Color bgColor;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback onTap;

  @override
  State<_BottomBtn> createState() => _BottomBtnState();
}

class _BottomBtnState extends State<_BottomBtn> {
  bool _hovered = false;
  bool _pressed = false;

  void _set(bool h, bool p) => setState(() {
    _hovered = h;
    _pressed = p;
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CharSelectUiSpec.bottomBarBtnRadius);
    final opacity = widget.enabled ? 1.0 : 0.45;

    Color? overlay;
    if (widget.enabled && _pressed) {
      overlay = widget.pressedColor;
    } else if (widget.enabled && _hovered) {
      overlay = widget.hoverColor;
    }

    return MouseRegion(
      onEnter: (_) => _set(true, false),
      onExit: (_) => _set(false, false),
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: (_) => _set(true, true),
        onTapUp: (_) => _set(true, false),
        onTapCancel: () => _set(false, false),
        child: Opacity(
          opacity: opacity,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: radius,
                    border: widget.borderColor != null
                        ? Border.all(color: widget.borderColor!)
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: GameUiFonts.kingHwaOldSong,
                      shadows: const [
                        Shadow(
                          blurRadius: 3,
                          color: Color(0xAA000000),
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                if (overlay != null)
                  Positioned.fill(child: ColoredBox(color: overlay)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 空狀態（無角色）─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '尚無角色',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 28,
              fontFamily: GameUiFonts.kingHwaOldSong,
            ),
          ),
          const SizedBox(height: 16),
          if (canCreate)
            Text(
              '請點擊下方「建立角色」開始你的修仙之旅',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontFamily: GameUiFonts.kingHwaOldSong,
              ),
            ),
        ],
      ),
    );
  }
}
