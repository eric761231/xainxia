import 'package:flutter/material.dart';

import '../../../models/char_create_template.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_ink_label.dart';
import 'char_create_text_styles.dart';

/// 單一屬性加點列（規格見 char_create_ui_spec.dart）。
class CharCreateStatRow extends StatelessWidget {
  const CharCreateStatRow({
    super.key,
    required this.label,
    required this.value,
    required this.base,
    required this.statKey,
    required this.iconPath,
    required this.enabled,
    required this.onAdjust,
  });

  final String label;
  final int value;
  final int base;
  final String statKey;
  final String iconPath;
  final bool enabled;
  final void Function(String statKey, int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    final canDecrease = enabled && value > base;
    final canIncrease =
        enabled && value < base + CharCreateTemplate.bonusPool;

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: CharCreateUiSpec.statRowWidthFraction,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: CharCreateUiSpec.statRowVMargin,
          ),
          child: CharCreateInkLabel(
            height: CharCreateUiSpec.statRowHeight,
            fit: CharCreateUiSpec.statRowImageFit,
            imageOffsetH: CharCreateUiSpec.statRowImageOffsetH,
            imageOffsetV: CharCreateUiSpec.statRowImageOffsetV,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (CharCreateUiSpec.statIconSize > 0) ...[
                  Image.asset(
                    iconPath,
                    width: CharCreateUiSpec.statIconSize,
                    height: CharCreateUiSpec.statIconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.star,
                      color: Colors.white54,
                      size: CharCreateUiSpec.statIconSize,
                    ),
                  ),
                  SizedBox(width: CharCreateUiSpec.statIconLabelGap),
                ],
                SizedBox(
                  width: CharCreateUiSpec.statLabelWidth,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: CharCreateTextStyles.shadowLabel(
                      fontSize: CharCreateUiSpec.statLabelFontSize,
                      color: Color(CharCreateUiSpec.colorStatLabel),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: CharCreateUiSpec.statValueLabelGap),
                SizedBox(
                  width: CharCreateUiSpec.statValueWidth,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: CharCreateTextStyles.shadowLabel(
                      fontSize: CharCreateUiSpec.statValueFontSize,
                      color: Colors.white70,
                    ),
                  ),
                ),
                SizedBox(width: CharCreateUiSpec.statAdjustBtnGap),
                _AdjustSymbol(
                  symbol: '−',
                  enabled: canDecrease,
                  onTap: () => onAdjust(statKey, -1),
                ),
                SizedBox(width: CharCreateUiSpec.statAdjustBtnGap),
                _AdjustSymbol(
                  symbol: '+',
                  enabled: canIncrease,
                  onTap: () => onAdjust(statKey, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdjustSymbol extends StatelessWidget {
  const _AdjustSymbol({
    required this.symbol,
    required this.enabled,
    required this.onTap,
  });

  final String symbol;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : CharCreateUiSpec.statAdjustBtnDisabledOpacity,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: CharCreateUiSpec.s(2),
          ),
          child: Text(
            symbol,
            style: CharCreateTextStyles.shadowLabel(
              fontSize: CharCreateUiSpec.statAdjustSymbolFontSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
