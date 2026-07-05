import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import 'char_create_text_styles.dart';

/// 水墨 label 底圖 + 置中文字（或自訂 [child] 疊加）。
class CharCreateInkLabel extends StatelessWidget {
  const CharCreateInkLabel({
    super.key,
    this.text,
    this.child,
    this.width,
    required this.height,
    this.fontSize = 14,
    this.textColor,
    this.asset = CharCreateUiAssets.inkBtn04,
    this.fit = BoxFit.fill,
    this.imageOffsetH = 0,
    this.imageOffsetV = 0,
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
          Transform.translate(
            offset: Offset(imageOffsetH, imageOffsetV),
            child: Image.asset(
              asset,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                CharCreateUiAssets.inkBtn01,
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
                style: CharCreateTextStyles.panelLabel(
                  fontSize: fontSize,
                  color: textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
