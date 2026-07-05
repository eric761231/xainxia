import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_ink_text_button.dart';

/// 創角畫面左上角返回（祥雲底 +「返回」文字陰影三態）。
class CharCreateBackButton extends StatelessWidget {
  const CharCreateBackButton({
    super.key,
    required this.onTap,
    required this.enabled,
  });

  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: CharCreateUiSpec.backBtnTop,
      left: CharCreateUiSpec.backBtnLeft,
      child: Padding(
        padding: EdgeInsets.all(CharCreateUiSpec.backSafeExtra),
        child: Opacity(
          opacity: enabled ? 1.0 : CharCreateUiSpec.backDisabledOpacity,
          child: CharCreateInkTextButton(
            label: '返回',
            bgAsset: CharCreateUiAssets.cloudLabel04,
            width: CharCreateUiSpec.backBtnWidth,
            height: CharCreateUiSpec.backBtnHeight,
            fontSize: CharCreateUiSpec.backLabelFontSize,
            enabled: enabled,
            onTap: onTap,
            fit: CharCreateUiSpec.backBtnImageFit,
            imageOffsetH: CharCreateUiSpec.backBtnImageOffsetH,
            imageOffsetV: CharCreateUiSpec.backBtnImageOffsetV,
          ),
        ),
      ),
    );
  }
}
