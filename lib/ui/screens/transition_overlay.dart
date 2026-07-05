import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../theme/game_ui_styles.dart';
import '../widgets/shared/progress_overlay_scaffold.dart';

/// 過場 overlay：背景 + 自訂訊息 + 進度條。
class TransitionOverlay extends StatelessWidget {
  const TransitionOverlay(this.game, {super.key});

  final MyGame game;

  static const _backgroundAsset = 'assets/images/loading.png';

  @override
  Widget build(BuildContext context) {
    return ProgressOverlayScaffold(
      background: Image.asset(
        _backgroundAsset,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: Color(0xFF140E0C)),
      ),
      message: ValueListenableBuilder<String>(
        valueListenable: game.transitionMessageNotifier,
        builder: (context, message, child) {
          return Text(
            message,
            style: GameUiStyles.shadowTextStyle(fontSize: 24),
          );
        },
      ),
      progress: game.progressNotifier,
    );
  }
}
