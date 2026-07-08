import 'dart:math' as math;
import 'dart:ui';

import 'iso_map_data.dart';

/// 互動指標的手繪動畫（不依賴圖檔）。
///
/// 依 [InteractKind] 在 tile 上方畫出對應的小動畫：
/// - portal：門拱 + 向上穿過的箭頭。
/// - gather：抓取的爪，隨相位開合。
/// - talk：對話框 + 輪播的三點。
/// - attack：揮劍的弧光。
///
/// [phase] 為 0..1 的循環相位（由呼叫端以時間累加取小數）。
/// [scale] 控制大小（hover 放大、平時的常駐標記較小），[opacity] 控制整體透明度。
class InteractionIndicator {
  InteractionIndicator._();

  static Color colorFor(InteractKind kind) {
    switch (kind) {
      case InteractKind.portal:
        return const Color(0xFF00E5FF);
      case InteractKind.gather:
        return const Color(0xFF66BB6A);
      case InteractKind.talk:
        return const Color(0xFFE8C86A);
      case InteractKind.attack:
        return const Color(0xFFEF5350);
    }
  }

  /// 平時的常駐標記：一顆低調的呼吸光點，讓玩家知道該格可互動。
  static void paintMarker(
    Canvas canvas,
    Offset center,
    InteractKind kind,
    double phase,
    double r,
  ) {
    final pulse = 0.5 + 0.5 * math.sin(phase * math.pi * 2);
    final color = colorFor(kind);
    canvas.drawCircle(
      center,
      r * (0.28 + 0.06 * pulse),
      Paint()..color = color.withValues(alpha: 0.30 + 0.25 * pulse),
    );
    canvas.drawCircle(
      center,
      r * 0.16,
      Paint()..color = color.withValues(alpha: 0.85),
    );
  }

  /// hover／走近時的完整動畫指標。
  static void paint(
    Canvas canvas,
    Offset center,
    InteractKind kind,
    double phase, {
    double scale = 1.0,
    double opacity = 1.0,
  }) {
    final color = colorFor(kind);
    // 柔光背光
    canvas.drawCircle(
      center,
      18 * scale,
      Paint()
        ..color = color.withValues(alpha: 0.14 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    switch (kind) {
      case InteractKind.portal:
        _portal(canvas, center, color, phase, scale, opacity);
        break;
      case InteractKind.gather:
        _gather(canvas, center, color, phase, scale, opacity);
        break;
      case InteractKind.talk:
        _talk(canvas, center, color, phase, scale, opacity);
        break;
      case InteractKind.attack:
        _attack(canvas, center, color, phase, scale, opacity);
        break;
    }
  }

  // 門拱 + 向上穿過的箭頭（有方向性：往上／往裡走）。
  static void _portal(Canvas canvas, Offset c, Color color, double phase,
      double s, double o) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.9 * o);
    // 門拱（上半圓 + 兩側柱）
    final w = 9.0 * s, h = 12.0 * s;
    final arch = Path()
      ..moveTo(c.dx - w, c.dy + h)
      ..lineTo(c.dx - w, c.dy - h * 0.2)
      ..arcToPoint(Offset(c.dx + w, c.dy - h * 0.2),
          radius: Radius.circular(w), clockwise: true)
      ..lineTo(c.dx + w, c.dy + h);
    canvas.drawPath(arch, stroke);
    // 穿過的箭頭：隨相位上移並淡出
    final t = phase;
    final ay = c.dy + h * 0.5 - t * h * 1.4;
    final aAlpha = (1 - t) * o;
    final ap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: aAlpha);
    final chev = 4.5 * s;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - chev, ay + chev)
        ..lineTo(c.dx, ay)
        ..lineTo(c.dx + chev, ay + chev),
      ap,
    );
  }

  // 抓取的爪：三根爪尖隨相位開合。
  static void _gather(Canvas canvas, Offset c, Color color, double phase,
      double s, double o) {
    final grip = 0.5 + 0.5 * math.sin(phase * math.pi * 2); // 0=合 1=開
    final spread = (3.0 + grip * 5.0) * s;
    final len = 8.0 * s;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.9 * o);
    // 掌心
    canvas.drawCircle(
        c, 2.4 * s, Paint()..color = color.withValues(alpha: 0.9 * o));
    // 三爪（上、左下、右下）
    for (final ang in [-math.pi / 2, math.pi * 0.75, math.pi * 0.25]) {
      final dir = Offset(math.cos(ang), math.sin(ang));
      final base = c + dir * spread;
      canvas.drawLine(c, base, p);
      canvas.drawLine(base, base + dir * len, p);
    }
  }

  // 對話框 + 輪播三點。
  static void _talk(Canvas canvas, Offset c, Color color, double phase,
      double s, double o) {
    final w = 13.0 * s, h = 9.0 * s;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: w * 2, height: h * 2),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(
        rect, Paint()..color = color.withValues(alpha: 0.22 * o));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * s
        ..color = color.withValues(alpha: 0.9 * o),
    );
    // 小尾巴
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 3 * s, c.dy + h)
        ..lineTo(c.dx - 6 * s, c.dy + h + 5 * s)
        ..lineTo(c.dx + 1 * s, c.dy + h),
      Paint()..color = color.withValues(alpha: 0.9 * o),
    );
    // 三點依相位輪亮
    final active = (phase * 3).floor() % 3;
    for (var i = 0; i < 3; i++) {
      final dx = (i - 1) * 7.0 * s;
      final on = i == active;
      canvas.drawCircle(
        Offset(c.dx + dx, c.dy),
        (on ? 2.4 : 1.6) * s,
        Paint()
          ..color = (on ? const Color(0xFFFFFFFF) : color)
              .withValues(alpha: (on ? 1.0 : 0.55) * o),
      );
    }
  }

  // 揮劍弧光：一道弧線隨相位掃過。
  static void _attack(Canvas canvas, Offset c, Color color, double phase,
      double s, double o) {
    final sweep = math.pi * 1.1;
    final start = -math.pi * 0.9 + phase * math.pi * 0.6;
    final rect = Rect.fromCircle(center: c, radius: 11 * s);
    // 弧光（隨相位淡出，營造揮舞殘影）
    final fade = (1 - phase).clamp(0.25, 1.0);
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * s
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.85 * o * fade),
    );
    // 劍身：一段短線指向弧尾
    final tipAng = start + sweep;
    final tip = c + Offset(math.cos(tipAng), math.sin(tipAng)) * 12 * s;
    final hilt = c + Offset(math.cos(tipAng), math.sin(tipAng)) * 3 * s;
    canvas.drawLine(
      hilt,
      tip,
      Paint()
        ..strokeWidth = 2.4 * s
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.95 * o),
    );
  }
}
