import 'package:flutter/material.dart';

import '../../../models/char_create_template.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_cloud_label.dart';
import 'char_create_ink_label.dart';
import 'char_create_pressable.dart';
import 'char_create_text_styles.dart';

/// 左側靈根選擇（規格見 char_create_ui_spec.dart）。
class CharCreateSpiritRootPanel extends StatelessWidget {
  const CharCreateSpiritRootPanel({
    super.key,
    required this.selectedIndex,
    required this.enabled,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onSelected;

  static const int _itemCount = 8;

  @override
  Widget build(BuildContext context) {
    final hPad = CharCreateUiSpec.spiritRootPanelPaddingH;
    final itemSpacing = CharCreateUiSpec.spiritRootItemSpacing;
    final itemHeight = CharCreateUiSpec.spiritRootCloudLabelHeight;

    return SizedBox(
      width: CharCreateUiSpec.leftPanelWidthResolved,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          hPad,
          CharCreateUiSpec.spiritRootPanelPaddingTop,
          hPad,
          CharCreateUiSpec.s(12),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: CharCreateUiSpec.spiritRootTitleBarWidthFraction,
                child: CharCreateCloudLabel(
                  text: '選擇靈根',
                  height: CharCreateUiSpec.spiritRootTitleBarHeight,
                  fontSize: CharCreateUiSpec.spiritRootTitleFontSize,
                  showBackground: false,
                ),
              ),
            ),
            SizedBox(height: CharCreateUiSpec.spiritRootTitleGap),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < _itemCount; index++) ...[
                      if (index > 0) SizedBox(height: itemSpacing),
                      SizedBox(
                        height: itemHeight,
                        child: ClipRect(
                          child: _SpiritRootItem(
                            root: CharCreateTemplate.spiritRootDetails[index],
                            isSelected: selectedIndex == index,
                            enabled: enabled,
                            onTap: () => onSelected(index),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpiritRootItem extends StatelessWidget {
  const _SpiritRootItem({
    required this.root,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final SpiritRootDetail root;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final elemColor = root.color;
    final nameColor = isSelected
        ? elemColor
        : Color(CharCreateUiSpec.spiritRootUnselectedNameColor);
    final descColor = isSelected
        ? Colors.white70
        : Color(CharCreateUiSpec.spiritRootUnselectedDescColor);

    return CharCreatePressable(
      enabled: enabled,
      onTap: onTap,
      child: CharCreateInkLabel(
        height: CharCreateUiSpec.spiritRootCloudLabelHeight,
        fit: CharCreateUiSpec.spiritRootItemImageFit,
        imageOffsetH: CharCreateUiSpec.spiritRootItemImageOffsetH,
        imageOffsetV: CharCreateUiSpec.spiritRootItemImageOffsetV,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: CharCreateUiSpec.spiritRootItemPaddingH,
            vertical: CharCreateUiSpec.spiritRootItemPaddingV,
          ),
          child: Row(
            children: [
              Image.asset(
                root.iconAsset,
                width: CharCreateUiSpec.spiritRootIconSize,
                height: CharCreateUiSpec.spiritRootIconSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.brightness_low,
                  color: elemColor,
                  size: CharCreateUiSpec.spiritRootIconSize,
                ),
              ),
              SizedBox(width: CharCreateUiSpec.s(6)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      root.name,
                      style: CharCreateTextStyles.shadowLabel(
                        fontSize: CharCreateUiSpec.spiritRootNameFontSize,
                        color: nameColor,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      root.description,
                      style: CharCreateTextStyles.shadowLabel(
                        fontSize: CharCreateUiSpec.spiritRootDescFontSize,
                        color: descColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
