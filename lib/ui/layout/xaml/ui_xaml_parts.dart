/// 各畫面共用的小型 spec 片段。
///
/// 「一個置中的文字」「一個輸入欄」這種東西每頁都有；讓每個 spec 各自把 centerX、
/// centerY、size、color 拆一遍，只會讓 clamp 範圍在不同頁面長出不同值。集中在這裡
/// 之後，`min`/`max` 只有一份。
library;

import 'package:flutter/material.dart';

import 'ui_xaml_node.dart';

/// 設計稿座標上的中心點與尺寸。
@immutable
class XamlBox {
  const XamlBox({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
  });

  final double centerX;
  final double centerY;
  final double width;
  final double height;

  /// 以畫面中心為基準的位移（設計稿像素）。
  ///
  /// 背景是 cover，版面中心跟著畫面中心走而不是左上角；用絕對座標定位會在
  /// 超寬螢幕上整組偏到一邊。
  Offset offsetFromCenter(double designWidth, double designHeight) =>
      Offset(centerX - designWidth / 2, centerY - designHeight / 2);

  static XamlBox from(UiXamlNode? node, XamlBox fallback) {
    if (node == null) return fallback;
    return XamlBox(
      centerX: node.d('centerX', fallback.centerX, min: -4000, max: 4000),
      centerY: node.d('centerY', fallback.centerY, min: -4000, max: 4000),
      width: node.d('width', fallback.width, min: 1, max: 4000),
      height: node.d('height', fallback.height, min: 1, max: 4000),
    );
  }
}

/// 一段置中文字。
@immutable
class XamlText {
  const XamlText({
    required this.text,
    required this.centerX,
    required this.centerY,
    required this.size,
    required this.color,
  });

  final String text;
  final double centerX;
  final double centerY;
  final double size;
  final Color color;

  Offset offsetFromCenter(double designWidth, double designHeight) =>
      Offset(centerX - designWidth / 2, centerY - designHeight / 2);

  static XamlText from(UiXamlNode? node, XamlText fallback) {
    if (node == null) return fallback;
    return XamlText(
      text: node.s('text', fallback.text),
      centerX: node.d('centerX', fallback.centerX, min: -4000, max: 4000),
      centerY: node.d('centerY', fallback.centerY, min: -4000, max: 4000),
      size: node.d('size', fallback.size, min: 6, max: 120),
      color: node.color('color', fallback.color),
    );
  }
}

/// 底線式輸入欄。
@immutable
class XamlField {
  const XamlField({
    required this.box,
    required this.hint,
    required this.textSize,
    required this.textColor,
    required this.hintColor,
    required this.lineColor,
    required this.focusLineColor,
    required this.lineWidth,
  });

  final XamlBox box;
  final String hint;
  final double textSize;
  final Color textColor;
  final Color hintColor;
  final Color lineColor;
  final Color focusLineColor;
  final double lineWidth;

  static XamlField from(UiXamlNode? node, XamlField fallback) {
    if (node == null) return fallback;
    return XamlField(
      box: XamlBox.from(node, fallback.box),
      hint: node.s('hint', fallback.hint),
      textSize: node.d('textSize', fallback.textSize, min: 6, max: 72),
      textColor: node.color('textColor', fallback.textColor),
      hintColor: node.color('hintColor', fallback.hintColor),
      lineColor: node.color('lineColor', fallback.lineColor),
      focusLineColor: node.color('focusLineColor', fallback.focusLineColor),
      lineWidth: node.d('lineWidth', fallback.lineWidth, min: 0.5, max: 8),
    );
  }
}

/// 文字按鈕（無膠囊底，靠文字與微光表達狀態）。
@immutable
class XamlButton {
  const XamlButton({
    required this.box,
    required this.text,
    required this.textSize,
    required this.textColor,
  });

  final XamlBox box;
  final String text;
  final double textSize;
  final Color textColor;

  static XamlButton from(UiXamlNode? node, XamlButton fallback) {
    if (node == null) return fallback;
    return XamlButton(
      box: XamlBox.from(node, fallback.box),
      text: node.s('text', fallback.text),
      textSize: node.d('textSize', fallback.textSize, min: 6, max: 72),
      textColor: node.color('textColor', fallback.textColor),
    );
  }
}

/// 無邊框墨色漸變長方形的幾何與外觀。
@immutable
class XamlInkFade {
  const XamlInkFade({
    required this.box,
    required this.color,
    required this.centerOpacity,
    required this.fadeX,
    required this.fadeY,
  });

  final XamlBox box;
  final Color color;
  final double centerOpacity;
  final double fadeX;
  final double fadeY;

  static XamlInkFade from(UiXamlNode? node, XamlInkFade fallback) {
    if (node == null) return fallback;
    // radius 在 XAML 裡可以寫，但只接受 0：規格要求直角。寫了別的值就記一行
    // 警告然後忽略，免得有人以為改得動、實際上畫面沒變還找不到原因。
    final radius = node.d('radius', 0, min: 0, max: 0);
    assert(radius == 0);
    return XamlInkFade(
      box: XamlBox.from(node, fallback.box),
      color: node.color('color', fallback.color),
      centerOpacity:
          node.d('centerOpacity', fallback.centerOpacity, min: 0, max: 1),
      fadeX: node.d('fadeX', fallback.fadeX, min: 0, max: 2000),
      fadeY: node.d('fadeY', fallback.fadeY, min: 0, max: 2000),
    );
  }
}
