import 'package:flutter/material.dart';

/// 載入進度條。
///
/// 刻意不放圓形滑塊或轉圈動畫 —— 進度由填充寬度與百分比文字表達即可。
/// 軌道為純灰白，填充保留藍色漸層以維持辨識度。
class LoadingBar extends StatelessWidget {
  final double progress;
  final double width;

  const LoadingBar({required this.progress, this.width = 600, super.key});

  /// 軌道底色（純灰白）。
  static const _trackColor = Color(0xFFE8E8E8);
  static const _trackBorder = Color(0xFFBFBFBF);

  /// 填充漸層（藍）。
  static const _fillStart = Color(0xFF4FC3F7);
  static const _fillEnd = Color(0xFF0288D1);

  /// 百分比文字：灰白軌道上必須用深色，白字會看不見。
  static const _labelColor = Color(0xFF333333);

  static const _barHeight = 20.0;
  static const _boxHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    const top = (_boxHeight - _barHeight) / 2;

    return SizedBox(
      width: width,
      height: _boxHeight,
      child: Stack(
        children: [
          // 軌道
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: _trackColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _trackBorder, width: 2),
              ),
            ),
          ),
          // 已完成部分
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_fillStart, _fillEnd],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // 百分比
          Align(
            alignment: Alignment.center,
            child: Text(
              '${(clamped * 100).toInt()}%',
              style: const TextStyle(
                color: _labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
