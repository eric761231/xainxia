import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../layout/xaml/specs/loading_ui_spec.dart';
import '../widgets/shared/progress_overlay_scaffold.dart';

/// 過場 overlay：與載入畫面同一套版面，只是訊息由 Dart 即時覆寫。
///
/// 兩者共用 `loading.xaml` 是刻意的 —— 它們在玩家眼中是同一個畫面，分成兩份設定
/// 只會讓其中一份慢慢長歪。
class TransitionOverlay extends StatelessWidget {
  const TransitionOverlay(this.game, {super.key});

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LoadingUiSpec.holder.revision,
      builder: (context, _, child) => ValueListenableBuilder<int?>(
        valueListenable: game.transitionPortraitSex,
        builder: (context, sex, child) => ProgressOverlayScaffold(
          portraitSex: sex,
          progress: game.progressNotifier,
          messageOverride: game.transitionMessageNotifier,
        ),
      ),
    );
  }
}
