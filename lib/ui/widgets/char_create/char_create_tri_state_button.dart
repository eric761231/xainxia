import 'package:flutter/material.dart';

/// 三態互動容器：pressed 優先於 hover，滑鼠與觸控共用 onTapDown/Up。
class CharCreateTriStateInteraction extends StatefulWidget {
  const CharCreateTriStateInteraction({
    super.key,
    required this.enabled,
    required this.builder,
    this.onTap,
    this.cursor = SystemMouseCursors.click,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final MouseCursor cursor;
  final Widget Function(BuildContext context, {required bool hovered, required bool pressed})
      builder;

  @override
  State<CharCreateTriStateInteraction> createState() =>
      _CharCreateTriStateInteractionState();
}

class _CharCreateTriStateInteractionState extends State<CharCreateTriStateInteraction> {
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
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      cursor: widget.enabled ? widget.cursor : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: widget.builder(context, hovered: _hovered, pressed: _pressed),
      ),
    );
  }
}

/// 三態切圖按鈕：normal / hover / pressed 資源路徑。
class CharCreateTriStateImage extends StatelessWidget {
  const CharCreateTriStateImage({
    super.key,
    required this.enabled,
    required this.normalAsset,
    required this.hoverAsset,
    required this.pressedAsset,
    required this.width,
    required this.height,
    this.onTap,
    this.fit = BoxFit.contain,
    this.fallbackAsset,
  });

  final bool enabled;
  final String normalAsset;
  final String hoverAsset;
  final String pressedAsset;
  final String? fallbackAsset;
  final double width;
  final double height;
  final BoxFit fit;
  final VoidCallback? onTap;

  String _resolveAsset({required bool hovered, required bool pressed}) {
    if (!enabled) return normalAsset;
    if (pressed) return pressedAsset;
    if (hovered) return hoverAsset;
    return normalAsset;
  }

  @override
  Widget build(BuildContext context) {
    return CharCreateTriStateInteraction(
      enabled: enabled,
      onTap: onTap,
      builder: (context, {required hovered, required pressed}) {
        final asset = _resolveAsset(hovered: hovered, pressed: pressed);
        final fallback = fallbackAsset ?? normalAsset;
        return SizedBox(
          width: width,
          height: height,
          child: Image.asset(
            asset,
            fit: fit,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              fallback,
              fit: fit,
              alignment: Alignment.center,
            ),
          ),
        );
      },
    );
  }
}
