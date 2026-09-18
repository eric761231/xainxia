import '../../theme/game_design.dart';
import 'package:flutter/material.dart';

import '../../layout/xaml/specs/loading_ui_spec.dart';

/// 無邊框載入進度條。
///
/// 形狀完全由 Flutter 畫 —— track、fill、圓角、裁切與柔光。素材（`loadingEnergy`）
/// 只負責填充區內水平循環的靈氣紋理。這條界線是刻意的：把進度條烘進 PNG 會讓
/// 「改高度」「改顏色」「改進度」三件事全部要重出圖，而百分比文字烘進去之後
/// 根本沒辦法跟著進度走。
///
/// 紋理缺檔時退回純色填充，不畫破圖。
class EnergyLoadingBar extends StatefulWidget {
  const EnergyLoadingBar({
    super.key,
    required this.progress,
    required this.spec,
    required this.scale,
  });

  /// 0.0–1.0；超出範圍會被夾住。
  final double progress;

  final LoadingUiSpec spec;

  /// 設計稿像素 → 邏輯像素的縮放係數。
  final double scale;

  @override
  State<EnergyLoadingBar> createState() => _EnergyLoadingBarState();
}

class _EnergyLoadingBarState extends State<EnergyLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 一個固定週期的計時器，實際位移由 pixelsPerSecond 換算 —— 這樣調整速度
    // 不需要重建 controller。
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final scale = widget.scale;
    final width = spec.barWidth * scale;
    final height = (spec.barHeight * scale).clamp(24.0, 36.0);
    final radius = BorderRadius.circular(spec.barRadius * scale);
    final value = widget.progress.clamp(0.0, 1.0);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 軌道。無邊框：這裡不畫 Border，靠底色與背景的明度差就夠分辨。
          DecoratedBox(
            decoration: BoxDecoration(color: spec.trackColor, borderRadius: radius),
          ),
          // 填充。先夾住圓角再放紋理，紋理才不會從圓角處溢出。
          ClipRRect(
            borderRadius: radius,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: _fill(spec, scale, height),
              ),
            ),
          ),
          if (spec.showLabel)
            Center(
              child: Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: spec.labelColor,
                  fontSize: (spec.labelSize * scale).clamp(14, 18),
                  fontFamily: GameDesign.text().fontFamily,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  shadows: GameDesign.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fill(LoadingUiSpec spec, double scale, double height) {
    final base = DecoratedBox(
      decoration: BoxDecoration(
        color: spec.fillColor,
        boxShadow: spec.glowOpacity <= 0 || spec.glowBlur <= 0
            ? null
            : [
                BoxShadow(
                  color: spec.glowColor.withValues(alpha: spec.glowOpacity),
                  blurRadius: spec.glowBlur * scale,
                ),
              ],
      ),
    );

    final texture = spec.textureAsset;
    if (texture == null) return base;

    return Stack(
      fit: StackFit.expand,
      children: [
        base,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final travel = spec.texturePixelsPerSecond *
                _controller.duration!.inMilliseconds /
                1000;
            return _ScrollingTexture(
              asset: texture,
              offset: -_controller.value * travel * scale,
              height: spec.textureHeight * scale,
              fallbackHeight: height,
            );
          },
        ),
      ],
    );
  }
}

/// 水平循環平鋪的紋理。
///
/// 用 [ImageRepeat.repeatX] 而不是自己排 Image：平鋪交給繪圖層做，才不會在
/// 接縫處出現半像素縫。
class _ScrollingTexture extends StatelessWidget {
  const _ScrollingTexture({
    required this.asset,
    required this.offset,
    required this.height,
    required this.fallbackHeight,
  });

  final String asset;
  final double offset;
  final double height;
  final double fallbackHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Image.asset(
          asset,
          repeat: ImageRepeat.repeatX,
          alignment: Alignment.centerLeft,
          height: height > 0 ? height : fallbackHeight,
          fit: BoxFit.fitHeight,
          gaplessPlayback: true,
          // 缺紋理時就讓底下的純色填充露出來，不要畫 Flutter 的破圖 icon。
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
