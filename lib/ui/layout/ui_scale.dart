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
    final value = compute(
      availableSize,
      designWidth: designWidth,
      designHeight: designHeight,
      scaleMin: scaleMin,
      scaleMax: scaleMax,
    );
    if (value != null) _scale = value;
  }

  /// 純函式版本：算出係數但不寫進共用的 [_scale]。
  ///
  /// 會疊在其他畫面之上的 overlay（載入、過場）要用這個。它們與底下的畫面同時
  /// 存在，若也去改那個全域值，底下那頁的版面會在 overlay 出現的瞬間跳動。
  ///
  /// 尺寸不合法時回傳 null，呼叫端保留原值。
  static double? compute(
    Size availableSize, {
    required double designWidth,
    required double designHeight,
    double scaleMin = 0.1,
    double scaleMax = 4.0,
  }) {
    if (availableSize.width <= 0 || availableSize.height <= 0) return null;
    if (designWidth <= 0 || designHeight <= 0) return null;
    final sx = availableSize.width / designWidth;
    final sy = availableSize.height / designHeight;
    return math.min(sx, sy).clamp(scaleMin, scaleMax);
  }

  static double s(double designPx) => designPx * _scale;
}
