import 'package:flutter/material.dart';

import '../../../models/char_create_template.dart';
import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_gender_selector.dart';
import 'char_create_stat_row.dart';
import 'char_create_stats_header.dart';

/// 右側性別與屬性加點（不含底部按鈕；規格見 char_create_ui_spec.dart）。
class CharCreateRightPanel extends StatelessWidget {
  const CharCreateRightPanel({
    super.key,
    required this.width,
    required this.sex,
    required this.enabled,
    required this.remainingPoints,
    required this.statsIntel,
    required this.statsSpirit,
    required this.statsAgility,
    required this.statsConstitution,
    required this.onSexChanged,
    required this.onAdjustStat,
    required this.onResetStats,
  });

  final double width;
  final int sex;
  final bool enabled;
  final int remainingPoints;
  final int statsIntel;
  final int statsSpirit;
  final int statsAgility;
  final int statsConstitution;
  final ValueChanged<int> onSexChanged;
  final void Function(String statKey, int delta) onAdjustStat;
  final VoidCallback onResetStats;

  Widget _buildStatsSection() {
    return Padding(
      padding: EdgeInsets.only(top: CharCreateUiSpec.statsSectionPaddingTop),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CharCreateStatsTitleBar(),
          SizedBox(height: CharCreateUiSpec.statsPointsRowGap),
          CharCreateStatRow(
            label: '神識',
            value: statsSpirit,
            base: CharCreateTemplate.baseSpirit,
            statKey: 'spirit',
            iconPath: CharCreateUiAssets.spiritIcon,
            enabled: enabled,
            onAdjust: onAdjustStat,
          ),
          CharCreateStatRow(
            label: '體魄',
            value: statsConstitution,
            base: CharCreateTemplate.baseConstitution,
            statKey: 'constitution',
            iconPath: CharCreateUiAssets.constitutionIcon,
            enabled: enabled,
            onAdjust: onAdjustStat,
          ),
          CharCreateStatRow(
            label: '敏捷',
            value: statsAgility,
            base: CharCreateTemplate.baseAgility,
            statKey: 'agility',
            iconPath: CharCreateUiAssets.agilityIcon,
            enabled: enabled,
            onAdjust: onAdjustStat,
          ),
          CharCreateStatRow(
            label: '悟性',
            value: statsIntel,
            base: CharCreateTemplate.baseIntel,
            statKey: 'intel',
            iconPath: CharCreateUiAssets.intelIcon,
            enabled: enabled,
            onAdjust: onAdjustStat,
          ),
          SizedBox(height: CharCreateUiSpec.statsGenderGap),
          CharCreateGenderSelector(
            sex: sex,
            enabled: enabled,
            onChanged: onSexChanged,
          ),
          SizedBox(height: CharCreateUiSpec.statsResetGap),
          CharCreateStatsResetPointsRow(
            remainingPoints: remainingPoints,
            enabled: enabled,
            onResetStats: onResetStats,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SingleChildScrollView(
        child: _buildStatsSection(),
      ),
    );
  }
}
