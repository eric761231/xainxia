import 'package:flutter/material.dart';

import '../../layout/char_create/char_create_ui_assets.dart';
import '../../layout/char_create/char_create_ui_spec.dart';
import 'char_create_text_styles.dart';

/// 底中角色名稱輸入條（規格見 char_create_ui_spec.dart）。
class CharCreateNameBar extends StatelessWidget {
  const CharCreateNameBar({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(
                CharCreateUiSpec.nameBarMinWidth,
                CharCreateUiSpec.nameBarWidth,
              )
            : CharCreateUiSpec.nameBarWidth;

        return SizedBox(
          width: width,
          height: CharCreateUiSpec.nameBarHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Transform.translate(
                offset: Offset(
                  CharCreateUiSpec.nameBarImageOffsetH,
                  CharCreateUiSpec.nameBarImageOffsetV,
                ),
                child: Image.asset(
                  CharCreateUiAssets.inputContact,
                  fit: BoxFit.fill,
                  width: width,
                  height: CharCreateUiSpec.nameBarHeight,
                ),
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                    CharCreateUiSpec.nameFieldTextOffsetH,
                    CharCreateUiSpec.nameFieldTextOffsetV,
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    expands: true,
                    maxLines: null,
                    style: CharCreateTextStyles.shadowLabel(
                      fontSize: CharCreateUiSpec.nameFieldFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ).copyWith(height: 1.0),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: CharCreateUiSpec.nameBarPaddingH,
                        vertical: CharCreateUiSpec.nameBarPaddingV,
                      ),
                      hintText: '點擊輸入你的修士名號',
                      hintStyle: CharCreateTextStyles.shadowLabel(
                        fontSize: CharCreateUiSpec.nameHintFontSize,
                        color: Colors.white.withValues(
                          alpha: CharCreateUiSpec.nameHintOpacity,
                        ),
                      ).copyWith(height: 1.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
