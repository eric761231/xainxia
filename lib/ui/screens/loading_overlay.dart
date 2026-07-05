import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../theme/game_ui_styles.dart';
import '../widgets/shared/loading_bar.dart';

/// 載入 overlay：Flutter 層顯示背景與進度，不依賴 Flame sprite 是否已就緒。
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay(this.game, {super.key});

  static const _primaryBg = 'assets/images/loading.png';
  static const _fallbackBg = 'assets/images/launch_bg.png';
  static const _fallbackColor = Color(0xFF140E0C);

  final MyGame game;

  Widget _backgroundImage(String asset) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        if (asset == _primaryBg) {
          return _backgroundImage(_fallbackBg);
        }
        return const ColoredBox(color: _fallbackColor);
      },
    );
  }

  Widget _loadingFooter(double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '載入中...',
          style: GameUiStyles.shadowTextStyle(fontSize: 24),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<double>(
          valueListenable: game.progressNotifier,
          builder: (context, value, child) {
            return LoadingBar(progress: value, width: width);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _backgroundImage(_primaryBg)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > 0
                      ? constraints.maxWidth * 0.6
                      : 360.0;
                  return _loadingFooter(width);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
