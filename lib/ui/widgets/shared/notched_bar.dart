import 'package:flutter/material.dart';

/// 內側切出 V 形凹口的進度條（中央 HP／MP 條專用）。
///
/// 凹口的斜邊與等級菱形的斜邊同角度，菱形正好嵌進兩條之間，
/// 三者咬合成一條完整的橫幅，而不是兩個方塊硬頂著一個菱形。
///
/// 顏色是參數而非寫死在 painter 裡 —— 之後要做中毒變綠、瀕死閃紅、
/// 護盾疊層，都只是換 paint 或多畫一層，不必動形狀。
class NotchedBar extends StatelessWidget {
  const NotchedBar({
    required this.fraction,
    required this.color,
    required this.height,
    required this.notch,
    required this.notchOnRight,
    super.key,
  });

  /// 填充比例 0..1。
  final double fraction;

  /// 填充色（實心）。
  final Color color;

  final double height;

  /// 凹口的水平深度。與菱形半寬相等時才會嚴絲合縫。
  final double notch;

  /// true = 凹口在右（HP，菱形在其右側）；false = 凹口在左（MP）。
  final bool notchOnRight;

  /// 未填充的底槽色。
  static const troughColor = Color(0x99000000);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        // 寬度吃滿父層給的空間（外層是 Row 的 Expanded）
        width: double.infinity,
        child: CustomPaint(
          painter: NotchedBarPainter(
            fraction: fraction.clamp(0.0, 1.0),
            color: color,
            notch: notch,
            notchOnRight: notchOnRight,
          ),
        ),
      );
}

class NotchedBarPainter extends CustomPainter {
  NotchedBarPainter({
    required this.fraction,
    required this.color,
    required this.notch,
    required this.notchOnRight,
  });

  final double fraction;
  final Color color;
  final double notch;
  final bool notchOnRight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final path = shapeOf(w, h, notch, notchOnRight);

    // 底槽
    canvas.drawPath(path, Paint()..color = NotchedBar.troughColor);

    // 填充：先夾住外形再畫矩形，這樣填充量變化不會破壞切角。
    // 實心色，不做漸層 —— 血條要一眼看得出是紅是藍，漸層反而把顏色沖淡。
    canvas.save();
    canvas.clipPath(path);
    final fillW = w * fraction;
    final rect = notchOnRight
        ? Rect.fromLTWH(0, 0, fillW, h)
        : Rect.fromLTWH(w - fillW, 0, fillW, h); // MP 由右往左填，向菱形靠攏
    canvas.drawRect(rect, Paint()..color = color);
    canvas.restore();
  }

  /// 外形：外側平口，內側順著菱形斜邊收成 V。
  static Path shapeOf(double w, double h, double notch, bool notchOnRight) {
    final d = notch.clamp(0.0, w);
    return notchOnRight
        ? (Path()
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w - d, h / 2)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close())
        : (Path()
          ..moveTo(w, 0)
          ..lineTo(0, 0)
          ..lineTo(d, h / 2)
          ..lineTo(0, h)
          ..lineTo(w, h)
          ..close());
  }

  @override
  bool shouldRepaint(covariant NotchedBarPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.notch != notch ||
      old.notchOnRight != notchOnRight;
}
