import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../layout/xaml/specs/loading_ui_spec.dart';
import '../widgets/shared/progress_overlay_scaffold.dart';

/// 載入 overlay：Flutter 層顯示背景與進度，不依賴 Flame sprite 是否已就緒。
///
/// 背景素材、訊息與進度條外觀都在 `assets/ui/xaml/loading.xaml`；這裡只接進度。
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay(this.game, {super.key});

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LoadingUiSpec.holder.revision,
      builder: (context, _, child) => ProgressOverlayScaffold(
        progress: game.progressNotifier,
      ),
    );
  }
}
