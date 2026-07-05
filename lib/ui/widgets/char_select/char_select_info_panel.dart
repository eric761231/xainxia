import 'package:flutter/material.dart';

import '../../../models/character_summary.dart';
import '../../theme/game_ui_fonts.dart';
import '../../layout/char_select/char_select_ui_spec.dart';
import '../char_create/char_create_cloud_label.dart';
import '../../layout/char_create/char_create_ui_assets.dart';

/// 右欄角色資訊面板（整合為單一 panel）。
class CharSelectInfoPanel extends StatelessWidget {
  const CharSelectInfoPanel({
    super.key,
    required this.character,
  });

  final GameCharacter character;

  @override
  Widget build(BuildContext context) {
    final sectionBg =
        Colors.black.withValues(alpha: CharSelectUiSpec.rightPanelSectionBgOpacity);
    final sectionRadius =
        BorderRadius.circular(CharSelectUiSpec.rightPanelSectionRadius);
    final labelColor = Color(CharSelectUiSpec.colorLabel);

    final faction = character.faction.isNotEmpty ? character.faction : '散修';
    final natalWeapon = character.natalWeapon.isNotEmpty ? character.natalWeapon : '無';
    final coreTechnique =
        character.coreTechnique.isNotEmpty ? character.coreTechnique : '無';
    final lifeJob = character.lifeJob.isNotEmpty ? character.lifeJob : '無';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CharSelectUiSpec.rightPanelPaddingH,
        vertical: CharSelectUiSpec.rightPanelPaddingV,
      ),
      child: Container(
        decoration: BoxDecoration(color: sectionBg, borderRadius: sectionRadius),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FractionallySizedBox(
                widthFactor: CharSelectUiSpec.infoPanelTitleBarWidthFraction,
                child: CharCreateCloudLabel(
                  text: '角色資訊',
                  height: CharSelectUiSpec.infoPanelTitleBarHeight,
                  fontSize: CharSelectUiSpec.infoPanelTitleFontSize,
                  asset: CharCreateUiAssets.cloudLabel05,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                CharSelectUiSpec.rightPanelPaddingH,
                8,
                CharSelectUiSpec.rightPanelPaddingH,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HP 條
                  _BarRow(
                    label: '生命',
                    current: character.hp,
                    max: character.hpMax,
                    fraction: character.hpFraction,
                    barColor: const Color(0xFFCC3333),
                    labelColor: labelColor,
                  ),
                  SizedBox(height: CharSelectUiSpec.infoPanelRowSpacing),
                  // MP 條
                  _BarRow(
                    label: '法力',
                    current: character.mp,
                    max: character.mpMax,
                    fraction: character.mpFraction,
                    barColor: const Color(0xFF3366CC),
                    labelColor: labelColor,
                  ),
                  SizedBox(height: CharSelectUiSpec.infoPanelRowSpacing * 1.5),
                  _Divider(),
                  SizedBox(height: CharSelectUiSpec.infoPanelRowSpacing * 1.5),
                  _InfoRow(label: '勢力', value: faction, labelColor: labelColor),
                  SizedBox(height: CharSelectUiSpec.infoPanelRowSpacing),
                  _InfoRow(label: '仙藝', value: natalWeapon, labelColor: labelColor),
                  SizedBox(height: CharSelectUiSpec.infoPanelRowSpacing),
                  _InfoRow(
                      label: '核心功法', value: coreTechnique, labelColor: labelColor),
                  SizedBox(height: CharSelectUiSpec.infoPanelRowSpacing),
                  _InfoRow(label: '生活職業', value: lifeJob, labelColor: labelColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 進度條列 ─────────────────────────────────────────────────

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.current,
    required this.max,
    required this.fraction,
    required this.barColor,
    required this.labelColor,
  });

  final String label;
  final int current;
  final int max;
  final double fraction;
  final Color barColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '$label：',
              style: TextStyle(
                color: labelColor,
                fontSize: CharSelectUiSpec.infoPanelLabelFontSize * 0.9,
                fontFamily: GameUiFonts.kingHwaOldSong,
              ),
            ),
            Text(
              '$current / $max',
              style: TextStyle(
                color: Colors.white70,
                fontSize: CharSelectUiSpec.infoPanelLabelFontSize * 0.9,
                fontFamily: GameUiFonts.kingHwaOldSong,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ── 通用文字資訊列 ────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelColor,
  });

  final String label;
  final String value;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CharSelectUiSpec.infoPanelRowHeight,
      child: Row(
        children: [
          Text(
            '$label：',
            style: TextStyle(
              color: labelColor,
              fontSize: CharSelectUiSpec.infoPanelLabelFontSize,
              fontFamily: GameUiFonts.kingHwaOldSong,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: CharSelectUiSpec.infoPanelValueFontSize,
                fontFamily: GameUiFonts.kingHwaOldSong,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 分隔線 ───────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}
