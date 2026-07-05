import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_btn01_label_button.dart';
import 'char_create_cloud_label.dart';
import 'char_create_text_styles.dart';

/// 「屬性分配」標題列：祥雲 label。
class CharCreateStatsTitleBar extends StatelessWidget {
  const CharCreateStatsTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: CharCreateUiSpec.statsTitleBarWidthFraction,
        child: CharCreateCloudLabel(
          text: '屬性分配',
          height: CharCreateUiSpec.statsTitleBarHeight,
          fontSize: CharCreateUiSpec.statsTitleFontSize,
          showBackground: false,
        ),
      ),
    );
  }
}

/// 重置點數 + 剩餘點數 + 數字（同一行）。
class CharCreateStatsResetPointsRow extends StatelessWidget {
  const CharCreateStatsResetPointsRow({
    super.key,
    required this.remainingPoints,
    required this.enabled,
    required this.onResetStats,
  });

  final int remainingPoints;
  final bool enabled;
  final VoidCallback onResetStats;

  @override
  Widget build(BuildContext context) {
    final pointsColor = remainingPoints > 0
        ? Colors.amberAccent
        : Colors.greenAccent;

    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CharCreateBtn01LabelButton(
            label: '重置點數',
            mode: CharCreateBtn01Mode.action,
            enabled: enabled,
            fontSize: CharCreateUiSpec.resetBtnFontSize,
            width: CharCreateUiSpec.resetBtnWidth,
            height: CharCreateUiSpec.resetBtnHeight,
            bgAsset: CharCreateUiAssets.inkBtn04,
            useCloudTextStyle: false,
            imageFit: CharCreateUiSpec.resetBtnImageFit,
            imageOffsetH: CharCreateUiSpec.resetBtnImageOffsetH,
            imageOffsetV: CharCreateUiSpec.resetBtnImageOffsetV,
            showBackground: false,
            onTap: onResetStats,
          ),
          SizedBox(width: CharCreateUiSpec.statsResetPointsRowGap),
          Text(
            '剩餘點數',
            style: CharCreateTextStyles.shadowLabel(
              fontSize: CharCreateUiSpec.statsPointsFontSize,
              color: Color(CharCreateUiSpec.colorStatLabel),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: CharCreateUiSpec.statsPointsValueGap),
          Text(
            '$remainingPoints',
            style: CharCreateTextStyles.shadowLabel(
              fontSize: CharCreateUiSpec.statsPointsFontSize,
              color: pointsColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
