import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_btn01_label_button.dart';

/// 性別選擇列（規格見 char_create_ui_spec.dart）。
class CharCreateGenderSelector extends StatelessWidget {
  const CharCreateGenderSelector({
    super.key,
    required this.sex,
    required this.enabled,
    required this.onChanged,
  });

  final int sex;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = CharCreateUiSpec.genderBtnGap;
        final maxBtnWidth = math.max(
          0,
          (constraints.maxWidth - gap) / 2,
        );
        final btnWidth = math.min(
          CharCreateUiSpec.genderBtnWidth,
          maxBtnWidth,
        ).toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CharCreateBtn01LabelButton(
              label: '男',
              selected: sex == 0,
              enabled: enabled,
              width: btnWidth,
              bgAsset: CharCreateUiAssets.cloudLabel04,
              onTap: () => onChanged(0),
            ),
            SizedBox(width: gap),
            CharCreateBtn01LabelButton(
              label: '女',
              selected: sex == 1,
              enabled: enabled,
              width: btnWidth,
              bgAsset: CharCreateUiAssets.cloudLabel04,
              onTap: () => onChanged(1),
            ),
          ],
        );
      },
    );
  }
}
