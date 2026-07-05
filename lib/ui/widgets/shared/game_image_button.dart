import 'package:flutter/material.dart';

import '../../theme/game_ui_styles.dart';

/// 圖片按鈕：底圖 + 可選文字。比 ElevatedButton 少一層 style/decoration 嵌套。
class GameImageButton extends StatelessWidget {
  const GameImageButton({
    required this.asset,
    required this.onPressed,
    this.label,
    this.width,
    this.height,
    super.key,
  });

  final String asset;
  final VoidCallback onPressed;
  final String? label;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            asset,
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _fallbackButton(),
          ),
          if (label != null)
            Text(label!, style: GameUiStyles.shadowTextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _fallbackButton() {
    return Container(
      width: width ?? 120,
      height: height ?? 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label ?? 'OK',
        style: GameUiStyles.shadowTextStyle(fontSize: 14),
      ),
    );
  }
}
