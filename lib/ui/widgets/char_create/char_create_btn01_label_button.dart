import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_ink_text_button.dart';

/// 水墨筆刷標籤按鈕：性別 toggle、重置 action 共用。
enum CharCreateBtn01Mode { toggle, action }

class CharCreateBtn01LabelButton extends StatelessWidget {
  const CharCreateBtn01LabelButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.enabled,
    this.mode = CharCreateBtn01Mode.toggle,
    this.selected = false,
    this.fontSize,
    this.width,
    this.height,
    this.bgAsset = CharCreateUiAssets.inkBtn01,
    this.useCloudTextStyle,
    this.imageFit,
    this.imageOffsetH,
    this.imageOffsetV,
    this.showBackground = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final CharCreateBtn01Mode mode;
  final bool selected;
  final double? fontSize;
  final double? width;
  final double? height;
  final String bgAsset;
  final bool? useCloudTextStyle;
  final BoxFit? imageFit;
  final double? imageOffsetH;
  final double? imageOffsetV;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final inkMode = mode == CharCreateBtn01Mode.toggle
        ? CharCreateInkButtonMode.toggle
        : CharCreateInkButtonMode.action;

    return CharCreateInkTextButton(
      label: label,
      bgAsset: bgAsset,
      width: width ?? CharCreateUiSpec.genderBtnWidth,
      height: height ?? CharCreateUiSpec.genderBtnHeight,
      fontSize: fontSize ?? CharCreateUiSpec.genderBtnFontSize,
      enabled: enabled,
      onTap: onTap,
      mode: inkMode,
      selected: selected,
      fit: imageFit ?? CharCreateUiSpec.genderBtnImageFit,
      imageOffsetH: imageOffsetH ?? CharCreateUiSpec.genderBtnImageOffsetH,
      imageOffsetV: imageOffsetV ?? CharCreateUiSpec.genderBtnImageOffsetV,
      useCloudTextStyle: useCloudTextStyle,
      showBackground: showBackground,
    );
  }
}
