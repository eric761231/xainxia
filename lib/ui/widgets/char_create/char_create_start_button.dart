import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_ink_text_button.dart';

/// 創角畫面右下角「進入遊戲」（水墨底 + 文字陰影三態）。
class CharCreateStartButton extends StatelessWidget {
  const CharCreateStartButton({
    super.key,
    required this.submitting,
    required this.onTap,
  });

  final bool submitting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = !submitting;

    return Positioned(
      right: CharCreateUiSpec.startBtnRight,
      bottom: CharCreateUiSpec.startBtnBottom,
      child: Opacity(
        opacity: enabled ? 1.0 : CharCreateUiSpec.startBtnDisabledOpacity,
        child: CharCreateInkTextButton(
          label: '進入遊戲',
          bgAsset: CharCreateUiAssets.cloudLabel04,
          width: CharCreateUiSpec.startBtnWidth,
          height: CharCreateUiSpec.startBtnHeight,
          fontSize: CharCreateUiSpec.startBtnFontSize,
          enabled: enabled,
          onTap: onTap,
          fit: CharCreateUiSpec.startBtnImageFit,
          imageOffsetH: CharCreateUiSpec.startBtnImageOffsetH,
          imageOffsetV: CharCreateUiSpec.startBtnImageOffsetV,
        ),
      ),
    );
  }
}
