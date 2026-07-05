import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'char_select_ui_config.dart';

/// 以 XML 基準稿（designWidth × designHeight）等比縮放固定 px。
abstract final class CharSelectUiScale {
  static double _scale = 1.0;

  static double get value => _scale;

  static void updateFrom(Size availableSize, CharSelectUiConfig config) {
    if (availableSize.width <= 0 || availableSize.height <= 0) return;
    final sx = availableSize.width / config.designWidth;
    final sy = availableSize.height / config.designHeight;
    _scale = math.min(sx, sy).clamp(config.scaleMin, config.scaleMax);
  }

  static double s(double designPx) => designPx * _scale;
}
