import 'package:flutter/material.dart';

import '../../../models/game_character.dart';
import '../../../models/char_create_template.dart';
import '../../theme/game_ui_fonts.dart';
import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_select/char_select_ui_spec.dart';

/// 左欄角色卡片（單一選取項目）。
class CharSelectCharCard extends StatefulWidget {
  const CharSelectCharCard({
    super.key,
    required this.character,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  final GameCharacter character;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<CharSelectCharCard> createState() => _CharSelectCharCardState();
}

class _CharSelectCharCardState extends State<CharSelectCharCard> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool v) {
    if (!widget.enabled || _hovered == v) return;
    setState(() => _hovered = v);
  }

  void _setPressed(bool v) {
    if (!widget.enabled || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final attrColor = Color(_attrColor(widget.character.attribute));

    final bgOpacity = selected
        ? CharSelectUiSpec.cardSelectedBgOpacity
        : CharSelectUiSpec.cardUnselectedBgOpacity;
    final borderColor = selected
        ? attrColor.withValues(alpha: CharSelectUiSpec.cardSelectedBorderOpacity)
        : Colors.white.withValues(alpha: CharSelectUiSpec.cardUnselectedBorderOpacity);
    final borderWidth = selected
        ? CharSelectUiSpec.cardSelectedBorderWidth
        : CharSelectUiSpec.cardUnselectedBorderWidth;

    Color? overlayColor;
    if (widget.enabled && _pressed) {
      overlayColor = CharSelectUiSpec.cardPressedOverlay;
    } else if (widget.enabled && _hovered) {
      overlayColor = CharSelectUiSpec.cardHoverOverlay;
    }

    final radius = BorderRadius.circular(CharSelectUiSpec.cardRadius);

    final attr = widget.character.attribute
        .clamp(0, CharCreateTemplate.attributeNames.length - 1);
    final attrName = CharCreateTemplate.attributeNames[attr];

    Widget card = Container(
      height: CharSelectUiSpec.cardHeight,
      padding: EdgeInsets.symmetric(
        horizontal: CharSelectUiSpec.cardPaddingH,
        vertical: CharSelectUiSpec.cardPaddingV,
      ),
      decoration: BoxDecoration(
        color: selected
            ? attrColor.withValues(alpha: bgOpacity)
            : Colors.black.withValues(alpha: bgOpacity),
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(
        children: [
          // 名稱 + 境界 / 等級
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.character.name,
                  style: TextStyle(
                    color: Color(CharSelectUiSpec.colorCardName),
                    fontSize: CharSelectUiSpec.cardNameFontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: GameUiFonts.kingHwaOldSong,
                    shadows: const [
                      Shadow(
                        blurRadius: 3,
                        color: Color(0xD9000000),
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.character.realm.isNotEmpty
                      ? widget.character.realm
                      : 'Lv.${widget.character.level}',
                  style: TextStyle(
                    color: Color(CharSelectUiSpec.colorCardLevel),
                    fontSize: CharSelectUiSpec.cardLevelFontSize,
                    fontFamily: GameUiFonts.kingHwaOldSong,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 靈根 icon + 屬性名（常駐小字，不用 Tooltip 避免 mouse tracker crash）
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                CharCreateUiAssets.attrIcon(widget.character.attribute),
                width: CharSelectUiSpec.cardAttrIconSize,
                height: CharSelectUiSpec.cardAttrIconSize,
                fit: BoxFit.contain,
              ),
              Text(
                attrName,
                style: TextStyle(
                  color: attrColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: GameUiFonts.kingHwaOldSong,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // 選中時加外圈光暈
    if (selected) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: attrColor.withValues(
                  alpha: CharSelectUiSpec.cardSelectedGlowOpacity),
              blurRadius: CharSelectUiSpec.cardSelectedGlowBlur,
              spreadRadius: 0,
            ),
          ],
        ),
        child: card,
      );
    }

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              card,
              if (overlayColor != null)
                Positioned.fill(child: ColoredBox(color: overlayColor)),
            ],
          ),
        ),
      ),
    );
  }

  static int _attrColor(int attr) {
    return switch (attr) {
      0 => 0xFFE8C547, // 金
      1 => 0xFF5CB85C, // 木
      2 => 0xFF4A9FD8, // 水
      3 => 0xFFE74C3C, // 火
      4 => 0xFF8B6914, // 土
      5 => 0xFF7EC8E3, // 風
      6 => 0xFF9B59B6, // 雷
      _ => 0xFFD68FD6, // 幻
    };
  }
}
