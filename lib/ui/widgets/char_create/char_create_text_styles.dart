import 'package:flutter/material.dart';

import '../../theme/game_ui_fonts.dart';
import '../../layout/char_create/char_create_ui_spec.dart';

/// 創角 UI 文字陰影樣式（按鈕三態 / 面板 label）。
abstract final class CharCreateTextStyles {
  static TextStyle _applyFont(TextStyle style) {
    return style.copyWith(fontFamily: GameUiFonts.kingHwaOldSong);
  }

  static TextStyle panelLabel({
    required double fontSize,
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return shadowLabel(
      fontSize: fontSize,
      color: color ?? Color(CharCreateUiSpec.colorTitle),
      fontWeight: fontWeight,
    );
  }

  /// 祥雲 label 靜態文字（深黑）。
  static TextStyle cloudPanelLabel({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _applyFont(
      TextStyle(
        color: CharCreateUiSpec.cloudTextNormalColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
      ),
    );
  }

  static TextStyle shadowLabel({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return _applyFont(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
        shadows: const [
          Shadow(
            blurRadius: 3.0,
            color: Color(0xD9000000),
            offset: Offset(1.0, 1.0),
          ),
          Shadow(
            blurRadius: 3.0,
            color: Color(0xD9000000),
            offset: Offset(-1.0, -1.0),
          ),
        ],
      ),
    );
  }

  static TextStyle buttonNormal({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _applyFont(
      TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
        shadows: _outlineShadows(
          CharCreateUiSpec.btnShadowNormalColor,
          CharCreateUiSpec.btnShadowNormalBlur,
        ),
      ),
    );
  }

  static TextStyle buttonHover({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _applyFont(
      TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
        shadows: _outlineShadows(
          CharCreateUiSpec.btnShadowHoverColor,
          CharCreateUiSpec.btnShadowHoverBlur,
        ),
      ),
    );
  }

  static TextStyle buttonPressed({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _applyFont(
      TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
        shadows: _outlineShadows(
          CharCreateUiSpec.btnShadowPressedColor,
          CharCreateUiSpec.btnShadowPressedBlur,
        ),
      ),
    );
  }

  static TextStyle buttonSelected({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _applyFont(
      TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
        shadows: _outlineShadows(
          CharCreateUiSpec.btnShadowSelectedColor,
          CharCreateUiSpec.btnShadowSelectedBlur,
        ),
      ),
    );
  }

  static TextStyle cloudButtonNormal({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _cloudStyle(
      color: CharCreateUiSpec.cloudTextNormalColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle cloudButtonHover({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _cloudStyle(
      color: CharCreateUiSpec.cloudTextHoverColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle cloudButtonPressed({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _cloudStyle(
      color: CharCreateUiSpec.cloudTextPressedColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle cloudButtonSelected({
    required double fontSize,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return _cloudStyle(
      color: CharCreateUiSpec.cloudTextSelectedColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle _cloudStyle({
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    return _applyFont(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
      ),
    );
  }

  static List<Shadow> _outlineShadows(
    Color color,
    double blur, {
    double spread = 1.0,
  }) {
    return [
      Shadow(
        color: color,
        blurRadius: blur,
        offset: Offset(spread, spread),
      ),
      Shadow(
        color: color,
        blurRadius: blur,
        offset: Offset(-spread, -spread),
      ),
      Shadow(
        color: color.withValues(alpha: 0.85),
        blurRadius: blur * 0.8,
        offset: Offset(spread * 0.5, spread * 0.5),
      ),
    ];
  }
}
