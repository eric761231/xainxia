import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../theme/game_ui_styles.dart';
import '../widgets/shared/loading_bar.dart';

/// 過場 overlay：背景 + 自訂訊息 + 進度條。
class TransitionOverlay extends StatelessWidget {
  const TransitionOverlay(this.game, {super.key});

  final MyGame game;

  static const _backgroundAsset = 'assets/images/loading.png';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundAsset,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: Color(0xFF140E0C)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > 0
                      ? constraints.maxWidth * 0.6
                      : 360.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: game.transitionMessageNotifier,
                        builder: (context, message, child) {
                          return Text(
                            message,
                            style: GameUiStyles.shadowTextStyle(fontSize: 24),
                          );
                        },
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
