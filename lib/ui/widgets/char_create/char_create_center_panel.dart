import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';

/// 中央性別立繪（石台已畫在 [CharCreateUiAssets.bg] 背景上）。
class CharCreateCenterPanel extends StatelessWidget {
  const CharCreateCenterPanel({
    super.key,
    required this.sex,
  });

  final int sex;

  @override
  Widget build(BuildContext context) {
    final portraitPath =
        sex == 0 ? CharCreateUiAssets.charMale : CharCreateUiAssets.charFemale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final widthFraction =
            CharCreateUiSpec.charPortraitImageWidthFractionResolved;
        final portraitW = maxW * widthFraction;

        return SizedBox(
          width: maxW,
          height: constraints.maxHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: CharCreateUiSpec.charPortraitBottomOffset,
              ),
              child: Image.asset(
                portraitPath,
                width: portraitW,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  size: portraitW * 0.6,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
