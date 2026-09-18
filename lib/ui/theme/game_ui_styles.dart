import 'package:flutter/material.dart';
import 'game_design.dart';
abstract final class GameUiStyles {
  static TextStyle shadowTextStyle({double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal}) =>
      GameDesign.text(size: fontSize, weight: fontWeight);
  static ButtonStyle capsuleButtonStyle({double alpha = 0.10}) => GameDesign.button();
}
