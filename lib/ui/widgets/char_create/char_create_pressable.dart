import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_spec.dart';

/// 創角 UI 通用懸停／按下疊色（桌面 MouseRegion + 行動 tap）。
class CharCreatePressable extends StatefulWidget {
  const CharCreatePressable({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.borderRadius,
    this.hoverColor,
    this.pressedColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final BorderRadius? borderRadius;
  final Color? hoverColor;
  final Color? pressedColor;

  @override
  State<CharCreatePressable> createState() => _CharCreatePressableState();
}

class _CharCreatePressableState extends State<CharCreatePressable> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    if (!widget.enabled || _hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final hoverColor =
        widget.hoverColor ?? CharCreateUiSpec.interactiveHoverOverlay;
    final pressedColor =
        widget.pressedColor ?? CharCreateUiSpec.interactivePressedOverlay;

    Color? overlayColor;
    if (widget.enabled && _pressed) {
      overlayColor = pressedColor;
    } else if (widget.enabled && _hovered) {
      overlayColor = hoverColor;
    }

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              if (overlayColor != null)
                Positioned.fill(
                  child: ColoredBox(color: overlayColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
