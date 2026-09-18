import 'package:flutter/material.dart';

import '../../../models/game_character.dart';
import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_select/char_select_ui_spec.dart';

/// 中央欄：角色立繪。
class CharSelectCenterPanel extends StatelessWidget {
  const CharSelectCenterPanel({super.key, required this.character});

  final GameCharacter character;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availHeight = constraints.maxHeight;
        // 與創角共用直式立繪。選角區保留 18% 的雲海／石台空間。
        final portraitH = availHeight * 0.82;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 立繪
            Positioned(
              bottom: CharSelectUiSpec.centerPortraitBottomOffset,
              left: 0,
              right: 0,
              height: portraitH,
              child: Image.asset(
                CharCreateUiAssets.portrait(character.sex),
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ],
        );
      },
    );
  }
}
