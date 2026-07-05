import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../theme/game_ui_styles.dart';
import '../widgets/shared/progress_overlay_scaffold.dart';

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

  @override
  Widget build(BuildContext context) {
    return ProgressOverlayScaffold(
      background: _backgroundImage(_primaryBg),
      message: Text(
        '載入中...',
        style: GameUiStyles.shadowTextStyle(fontSize: 24),
      ),
      progress: game.progressNotifier,
    );
  }
}
