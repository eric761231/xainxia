import 'package:flutter/material.dart';
import 'game_ui_fonts.dart';

/// Shared logical-pixel tokens. Text and controls are never scaled with artwork.
abstract final class GameDesign {
  static const jade = Color(0xFF89D5CC);
  static const gold = Color(0xFFE8CE8B);
  static const ink = Color(0xEE152629);
  static const danger = Color(0xFFFFA59B);
  static const muted = Color(0xFFE0EBE9);
  static const minTarget = 44.0;
  static const outline = <Shadow>[
    Shadow(color: Colors.black, offset: Offset(-1, -1)),
    Shadow(color: Colors.black, offset: Offset(0, -1)),
    Shadow(color: Colors.black, offset: Offset(1, -1)),
    Shadow(color: Colors.black, offset: Offset(-1, 0)),
    Shadow(color: Colors.black, offset: Offset(1, 0)),
    Shadow(color: Colors.black, offset: Offset(-1, 1)),
    Shadow(color: Colors.black, offset: Offset(0, 1)),
    Shadow(color: Colors.black, offset: Offset(1, 1)),
  ];
  static TextStyle text({double size = 16, Color color = Colors.white,
    FontWeight weight = FontWeight.normal}) => TextStyle(
      fontFamily: GameUiFonts.kingHwaOldSong, fontSize: size.clamp(14, 36),
      color: color, fontWeight: weight, shadows: outline,
    );
  static ButtonStyle button({bool primary = false, bool danger = false}) =>
    TextButton.styleFrom(
      minimumSize: const Size(44, 48),
      foregroundColor: danger ? GameDesign.danger : Colors.white,
      backgroundColor: primary ? const Color(0xD9306664) : Colors.transparent,
      disabledForegroundColor: Colors.white54,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: text(size: 18),
    );
}
