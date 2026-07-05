import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 以 XML 基準稿（designWidth × designHeight）等比縮放固定 px。
///
/// 各畫面 spec 共用同一縮放係數；因畫面不同時顯示，build 前皆會呼叫
/// [updateFrom] 重算，故單一靜態 [_scale] 安全。
abstract final class UiScale {
  static double _scale = 1.0;

  static double get value => _scale;

  static void updateFrom(
    Size availableSize, {
    required double designWidth,
    required double designHeight,
    required double scaleMin,
    required double scaleMax,
  }) {
    if (availableSize.width <= 0 || availableSize.height <= 0) return;
    final sx = availableSize.width / designWidth;
    final sy = availableSize.height / designHeight;
    _scale = math.min(sx, sy).clamp(scaleMin, scaleMax);
  }

  static double s(double designPx) => designPx * _scale;
}
