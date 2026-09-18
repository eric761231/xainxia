import 'dart:math' as math;
import 'dart:ui';

/// 石板地面的程序化繪製。
///
/// 取代原本「半透明灰菱形 + 白色細線」的畫法 —— 那個版本每一格都長得一模一樣，
/// 看起來像網格線稿而不是地面。這裡替每一格加上**由座標決定**的深淺、裂痕、
/// 缺角與斑點，讓地面有磨損感。
///
/// 兩個關鍵約束：
///
/// 1. **必須半透明。** 這一層是畫在地圖底圖之上的（`render()` 先畫 `_bgImage`
///    再畫圖層），黑森林那種有美術底圖的地圖靠它透出來。做成不透明會蓋掉美術。
///
/// 2. **必須由座標決定（deterministic）。** 用 `Random()` 每幀都會抽到不同結果，
///    地面會整片閃爍。這裡用整數雜湊，同一格永遠得到同一組數字，
///    不需要快取也不會抖動。
class StoneFloor {
  StoneFloor._();

  /// 基底色相（偏冷的深灰）。實際每格會在此之上做深淺變化。
  static const _baseR = 0x30;
  static const _baseG = 0x30;
  static const _baseB = 0x38;

  /// 整數雜湊：同一組 (x, y, salt) 永遠回傳同一個值。
  ///
  /// 刻意不用 `dart:math` 的 `Random` —— 那需要為每格建立實例並持有種子，
  /// 而這裡每幀都要對數百格取值，純整數運算便宜得多。
  static int _hash(int x, int y, int salt) {
    var h = (x * 0x1F1F1F1F) ^ (y * 0x2545F491) ^ (salt * 0x9E3779B9);
    h &= 0x7FFFFFFF;
    h ^= h >> 13;
    h = (h * 0x5BD1E995) & 0x7FFFFFFF;
    return h ^ (h >> 15);
  }

  /// 0.0 ~ 1.0 的決定性亂數。
  static double _rand(int x, int y, int salt) =>
      (_hash(x, y, salt) & 0xFFFF) / 0xFFFF;

  /// 畫一格石板。[topX]/[topY] 是菱形的上頂點。
  static void paintTile(
    Canvas canvas,
    Path diamond,
    int tx,
    int ty,
    double topX,
    double topY,
    double halfW,
    double halfH,
  ) {
    // ── 底色：每格深淺不同，讓石板不像同一塊塑膠 ──
    // ±14 的亮度差在半透明疊加後大約是肉眼剛好分得出的程度。
    final shade = ((_rand(tx, ty, 1) - 0.5) * 40).round();
    // 少數幾格明顯更深，模擬水漬／苔痕，避免整片過於均勻
    final damp = _rand(tx, ty, 7) < 0.10 ? -18 : 0;
    final alpha = 0x8C + (_rand(tx, ty, 2) * 0x18).round();

    canvas.drawPath(
      diamond,
      Paint()
        ..color = Color.fromARGB(
          alpha,
          (_baseR + shade + damp).clamp(0, 255),
          (_baseG + shade + damp).clamp(0, 255),
          (_baseB + shade + damp).clamp(0, 255),
        ),
    );

    // ── 接縫：暗色凹槽，而不是亮白線 ──
    //
    // 原本畫的是 0xB0FFFFFF 的白框，整張地面因此看起來像方格紙。
    // 真實石板之間是**凹下去的暗縫**，所以這裡改成暗色描邊；
    // 亮部另外只加在上緣（見下），形成受光的斜面感。
    canvas.drawPath(
      diamond,
      Paint()
        ..color = Color.fromARGB(
          0x55 + (_rand(tx, ty, 3) * 0x22).round(),
          0x08,
          0x08,
          0x0C,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── 上緣高光：只打左上與右上兩條邊 ──
    // 光從上方來，只有朝上的兩條邊會反光。四邊都打亮就會變回方格紙。
    final hi = Path()
      ..moveTo(topX - halfW, topY + halfH)
      ..lineTo(topX, topY)
      ..lineTo(topX + halfW, topY + halfH);
    canvas.drawPath(
      hi,
      Paint()
        ..color = Color.fromARGB(
          0x22 + (_rand(tx, ty, 4) * 0x1E).round(),
          0xFF,
          0xFF,
          0xFF,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    canvas.save();
    // 裂痕與缺角都不該越出石板邊界
    canvas.clipPath(diamond);

    _paintCracks(canvas, tx, ty, topX, topY, halfW, halfH);
    _paintChip(canvas, tx, ty, topX, topY, halfW, halfH);
    _paintSpeckles(canvas, tx, ty, topX, topY, halfW, halfH);

    canvas.restore();
  }

  /// 裂痕：多段折線 + 分岔，並且由粗到細收尾。
  ///
  /// 前一版是單純三點折線、等寬 —— 看起來像被刀劃了一道，不像裂開。
  /// 真實裂痕有三個特徵，這裡都做了：
  ///   1. **由粗到細**：起點最寬，往尾端收成髮絲。Canvas 沒有漸變線寬，
  ///      所以拆成多段、逐段調 strokeWidth。
  ///   2. **不規則**：每一段的方向都帶抖動，不是平滑曲線。
  ///   3. **分岔**：主裂痕中段長出一條較短的支線。
  static void _paintCracks(Canvas canvas, int tx, int ty, double topX,
      double topY, double halfW, double halfH) {
    if (_rand(tx, ty, 11) > 0.42) return;

    // 起點落在菱形上半某條邊上
    final t0 = _rand(tx, ty, 12);
    var px = topX - halfW + t0 * halfW * 2;
    var py = topY + (px - topX).abs() / 2;

    final dirX = _rand(tx, ty, 14) < 0.5 ? -1.0 : 1.0;
    final segs = 3 + (_rand(tx, ty, 16) * 3).floor(); // 3~5 段
    final baseW = 1.0 + _rand(tx, ty, 17) * 0.5;
    final alpha = 0x70 + (_rand(tx, ty, 15) * 0x38).round();

    // 記下中段位置，等一下從那裡長分岔
    double branchX = px;
    double branchY = py;

    for (var i = 0; i < segs; i++) {
      // 每段長度遞減，方向帶抖動
      final f = 1.0 - i / segs;
      final jitter = (_rand(tx + i, ty, 18) - 0.5) * 1.4;
      final nx = px + (dirX + jitter) * halfW * 0.22 * f;
      final ny = py + halfH * 0.30 * f;

      canvas.drawLine(
        Offset(px, py),
        Offset(nx, ny),
        Paint()
          ..color = Color.fromARGB(alpha, 0x08, 0x08, 0x0C)
          // 尾端收細：最後一段只剩三成寬
          ..strokeWidth = baseW * (0.3 + 0.7 * f)
          ..strokeCap = StrokeCap.round,
      );

      px = nx;
      py = ny;
      if (i == segs ~/ 2) {
        branchX = px;
        branchY = py;
      }
    }

    // 分岔：約一半的裂痕才有，長度是主裂痕的一小段
    if (_rand(tx, ty, 19) < 0.55) {
      final bDir = -dirX; // 往主裂痕的反向岔開，比較像應力裂開
      var bx = branchX;
      var by = branchY;
      for (var i = 0; i < 2; i++) {
        final f = 1.0 - i / 2;
        final jitter = (_rand(tx, ty + i, 20) - 0.5) * 1.2;
        final nx = bx + (bDir + jitter) * halfW * 0.16 * f;
        final ny = by + halfH * 0.18 * f;
        canvas.drawLine(
          Offset(bx, by),
          Offset(nx, ny),
          Paint()
            ..color = Color.fromARGB((alpha * 0.8).round(), 0x08, 0x08, 0x0C)
            ..strokeWidth = baseW * 0.45 * f
            ..strokeCap = StrokeCap.round,
        );
        bx = nx;
        by = ny;
      }
    }
  }

  /// 缺角：沿著石板邊緣的不規則破口，並在內緣打一道亮邊。
  ///
  /// 前一版是對稱的小菱形，看起來像貼上去的黑色方塊。改成不規則多邊形之後
  /// 才像「碎掉」；而真正讓它有立體感的是**內緣的亮邊** ——
  /// 石頭崩掉後露出的新鮮斷面會受光，只有暗塊是看不出深度的。
  static void _paintChip(Canvas canvas, int tx, int ty, double topX,
      double topY, double halfW, double halfH) {
    if (_rand(tx, ty, 21) > 0.26) return;

    // 四個頂點：上、右、下、左
    final corner = (_rand(tx, ty, 22) * 4).floor();
    late double cx;
    late double cy;
    switch (corner) {
      case 0:
        cx = topX;
        cy = topY;
      case 1:
        cx = topX + halfW;
        cy = topY + halfH;
      case 2:
        cx = topX;
        cy = topY + halfH * 2;
      default:
        cx = topX - halfW;
        cy = topY + halfH;
    }

    // 以缺角頂點為中心，取 5 個帶抖動的點連成不規則破口
    final r = 0.16 + _rand(tx, ty, 23) * 0.20;
    final pts = <Offset>[];
    for (var i = 0; i < 5; i++) {
      final a = (i / 4) * math.pi; // 半圈就夠，破口不會是整圈
      final jitter = 0.55 + _rand(tx + i, ty, 24) * 0.75;
      final rad = r * jitter;
      pts.add(Offset(
        cx + halfW * rad * math.cos(a + corner * math.pi / 2),
        cy + halfH * rad * math.sin(a + corner * math.pi / 2),
      ));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    // 破口本體：凹陷的陰影
    canvas.drawPath(path, Paint()..color = const Color(0x66000000));
    // 內緣亮邊：露出的新鮮斷面受光，這道線才是立體感的來源
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x3AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  /// 斑點：兩三個極小的深色點，近看才發現，用來打散平面感。
  static void _paintSpeckles(Canvas canvas, int tx, int ty, double topX,
      double topY, double halfW, double halfH) {
    final count = (_rand(tx, ty, 31) * 3).floor();
    final paint = Paint()..color = const Color(0x33000000);
    for (var i = 0; i < count; i++) {
      // 在菱形內取點：先取單位方格再壓成菱形座標
      final u = _rand(tx, ty, 32 + i * 2) - 0.5;
      final v = _rand(tx, ty, 33 + i * 2) - 0.5;
      final px = topX + (u - v) * halfW;
      final py = topY + halfH + (u + v) * halfH;
      canvas.drawCircle(Offset(px, py), 0.7, paint);
    }
  }
}
