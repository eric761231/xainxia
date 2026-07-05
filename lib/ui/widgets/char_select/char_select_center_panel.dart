import 'package:flutter/material.dart';

import '../../../models/game_character.dart';
import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_select/char_select_ui_spec.dart';

/// 中央欄：角色立繪。
class CharSelectCenterPanel extends StatelessWidget {
  const CharSelectCenterPanel({
    super.key,
    required this.character,
  });

  final GameCharacter character;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availWidth = constraints.maxWidth;
        final availHeight = constraints.maxHeight;
        final portraitW = availWidth * CharSelectUiSpec.centerPortraitWidthFraction;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 立繪
            Positioned(
              bottom: CharSelectUiSpec.centerPortraitBottomOffset,
              left: (availWidth - portraitW) / 2,
              width: portraitW,
              height: availHeight,
              child: Image.asset(
                CharCreateUiAssets.portrait(character.sex),
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ],
        );
      },
    );
  }
}
