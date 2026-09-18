import 'package:flutter/material.dart';

/// 無邊框的墨色漸變長方形。
///
/// 規格上有三條硬性條件（接手計畫 §4），而且都是「看起來差不多、但做錯就不對」
/// 的那種：
///
/// * **直角**：`radius = 0`，不套 `ClipRRect`。圓角會讓它看起來像卡片，
///   而這裡要的是一塊化開的墨。
/// * **無邊框**：不畫 `Border`。邊界由淡出本身表達。
/// * **四邊淡出**：由中央往上下左右都要淡到全透明，不是圓形霧團，也不是
///   單向漸層。
///
/// 作法是兩層 [ShaderMask] 以 [BlendMode.dstIn] 相乘：一層水平淡出、一層垂直
/// 淡出。兩者的 alpha 相乘之後，中央是 [centerOpacity] 的平台，四邊各自在
/// [fadeX] / [fadeY] 的距離內收到 0，四個角自然最淡。
///
/// 用 CustomPainter 逐像素算也可以，但那會在每次重繪時跑一遍 CPU；漸層交給
/// 繪圖層做同樣精確，而且免費。
class InkFadeRect extends StatelessWidget {
  const InkFadeRect({
    super.key,
    required this.width,
    required this.height,
    this.color = const Color(0xFF0E0F12),
    this.centerOpacity = 0.72,
    this.fadeX = 120,
    this.fadeY = 100,
    this.child,
  });

  final double width;
  final double height;

  /// 墨色本身。
  final Color color;

  /// 中央平台的不透明度。
  final double centerOpacity;

  /// 左右各自的淡出距離（邏輯像素）。
  final double fadeX;

  /// 上下各自的淡出距離（邏輯像素）。
  final double fadeY;

  /// 疊在墨色之上的內容；不受淡出影響。
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _fade(
            axis: Axis.horizontal,
            extent: width,
            fade: fadeX,
            child: _fade(
              axis: Axis.vertical,
              extent: height,
              fade: fadeY,
              child: ColoredBox(
                color: color.withValues(
                  alpha: centerOpacity.clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }

  Widget _fade({
    required Axis axis,
    required double extent,
    required double fade,
    required Widget child,
  }) {
    // 淡出距離不能超過一半，否則兩側的斜坡會交疊，中央就沒有平台了。
    final span = extent <= 0 ? 0.0 : (fade.clamp(0.0, extent / 2) / extent);
    if (span <= 0) return child;

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: axis == Axis.horizontal
            ? Alignment.centerLeft
            : Alignment.topCenter,
        end: axis == Axis.horizontal
            ? Alignment.centerRight
            : Alignment.bottomCenter,
        // dstIn 只看 alpha，顏色本身無關緊要。
        colors: const [
          Color(0x00000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0x00000000),
        ],
        stops: [0.0, span, 1.0 - span, 1.0],
      ).createShader(bounds),
      child: child,
    );
  }
}
