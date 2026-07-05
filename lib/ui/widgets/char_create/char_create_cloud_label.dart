import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import 'char_create_text_styles.dart';

/// 祥雲底圖 + 置中文字（或自訂 [child] 疊加）。
class CharCreateCloudLabel extends StatelessWidget {
  const CharCreateCloudLabel({
    super.key,
    this.text,
    this.child,
    this.width,
    required this.height,
    this.fontSize = 14,
    this.textColor,
    this.asset = CharCreateUiAssets.cloudLabel01,
    this.fit = BoxFit.fill,
    this.imageOffsetH = 0,
    this.imageOffsetV = 0,
    this.showBackground = true,
  }) : assert(text != null || child != null);

  final String? text;
  final Widget? child;
  final double? width;
  final double height;
  final double fontSize;
  final Color? textColor;
  final String asset;
  final BoxFit fit;
  final double imageOffsetH;
  final double imageOffsetV;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          if (showBackground)
            Transform.translate(
              offset: Offset(imageOffsetH, imageOffsetV),
              child: Image.asset(
                asset,
                fit: fit,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  CharCreateUiAssets.cloudLabel02,
                  fit: fit,
                ),
              ),
            ),
          if (child != null)
            child!
          else
            Center(
              child: Text(
                text!,
                style: CharCreateTextStyles.cloudPanelLabel(
                  fontSize: fontSize,
                ).copyWith(
                  color: textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
