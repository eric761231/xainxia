import 'package:flutter/material.dart';

/// Clamp the visible title bar, including close control, inside the viewport.
Offset boundedPanelOffset(BuildContext context, GlobalKey contentKey,
    Offset current, Offset delta) {
  final box = contentKey.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return current;
  final origin = box.localToGlobal(Offset.zero);
  final size = MediaQuery.sizeOf(context);
  final safe = MediaQuery.paddingOf(context);
  final right = (size.width - safe.right - box.size.width - 8)
      .clamp(safe.left + 8, double.infinity);
  final bottom = (size.height - safe.bottom - 48)
      .clamp(safe.top + 8, double.infinity);
  final x = (origin.dx + delta.dx).clamp(safe.left + 8, right);
  final y = (origin.dy + delta.dy).clamp(safe.top + 8, bottom);
  return current + Offset(x - origin.dx, y - origin.dy);
}
