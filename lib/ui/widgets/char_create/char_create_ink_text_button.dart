import 'package:flutter/material.dart';

import 'char_create_text_styles.dart';
import 'char_create_tri_state_button.dart';

/// 水墨筆刷 / 祥雲底 + 文字；互動只切換文字樣式，不換底圖。
enum CharCreateInkButtonMode { action, toggle }

class CharCreateInkTextButton extends StatelessWidget {
  const CharCreateInkTextButton({
    super.key,
    required this.label,
    required this.bgAsset,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.enabled,
    required this.onTap,
    this.mode = CharCreateInkButtonMode.action,
    this.selected = false,
    this.fit = BoxFit.fill,
    this.useCloudTextStyle,
    this.imageOffsetH = 0,
    this.imageOffsetV = 0,
    this.showBackground = true,
  });

  final String label;
  final String bgAsset;
  final double width;
  final double height;
  final double fontSize;
  final bool enabled;
  final VoidCallback? onTap;
  final CharCreateInkButtonMode mode;
  final bool selected;
  final BoxFit fit;
  final bool? useCloudTextStyle;
  final double imageOffsetH;
  final double imageOffsetV;
  final bool showBackground;

  bool get _isCloudBackground =>
      useCloudTextStyle ?? bgAsset.contains('cloud_label');

  TextStyle _resolveStyle({
    required bool hovered,
    required bool pressed,
  }) {
    if (_isCloudBackground) {
      if (mode == CharCreateInkButtonMode.toggle &&
          selected &&
          !hovered &&
          !pressed) {
        return CharCreateTextStyles.cloudButtonSelected(fontSize: fontSize);
      }
      if (pressed) {
        return CharCreateTextStyles.cloudButtonPressed(fontSize: fontSize);
      }
      if (hovered) {
        return CharCreateTextStyles.cloudButtonHover(fontSize: fontSize);
      }
      return CharCreateTextStyles.cloudButtonNormal(fontSize: fontSize);
    }

    if (mode == CharCreateInkButtonMode.toggle &&
        selected &&
        !hovered &&
        !pressed) {
      return CharCreateTextStyles.buttonSelected(fontSize: fontSize);
    }
    if (pressed) {
      return CharCreateTextStyles.buttonPressed(fontSize: fontSize);
    }
    if (hovered) {
      return CharCreateTextStyles.buttonHover(fontSize: fontSize);
    }
    return CharCreateTextStyles.buttonNormal(fontSize: fontSize);
  }

  @override
  Widget build(BuildContext context) {
    return CharCreateTriStateInteraction(
      enabled: enabled,
      onTap: onTap,
      builder: (context, {required hovered, required pressed}) {
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
                    bgAsset,
                    fit: fit,
                    width: width,
                    height: height,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              Center(
                child: Text(
                  label,
                  style: _resolveStyle(hovered: hovered, pressed: pressed),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
