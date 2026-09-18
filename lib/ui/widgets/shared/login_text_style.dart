import 'package:flutter/material.dart';
import '../../theme/game_design.dart';
TextStyle loginTextStyle(double size, {bool enabled = true}) =>
  GameDesign.text(size: size, color: enabled ? Colors.white : Colors.white70);
