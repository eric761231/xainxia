import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

/// XML 屬性解析共用工具（char_create / char_select loader 共用）。
///
/// 皆為「取不到或解析失敗即回傳 fallback」的寬鬆解析。
abstract final class XmlAttr {
  /// double 屬性。
  static double d(XmlElement el, String name, double fallback) {
    final v = el.getAttribute(name);
    if (v == null) return fallback;
    return double.tryParse(v) ?? fallback;
  }

  /// 非空字串屬性。
  static String s(XmlElement el, String name, String fallback) {
    final v = el.getAttribute(name);
    if (v == null || v.isEmpty) return fallback;
    return v;
  }

  /// int 屬性。
  static int i(XmlElement el, String name, int fallback) {
    final v = el.getAttribute(name);
    if (v == null) return fallback;
    return int.tryParse(v) ?? fallback;
  }

  /// 以 16 進位解析的顏色整數（存 int 用）。可含或不含前導 `#`。
  static int colorInt(XmlElement el, String name, int fallback) {
    final v = el.getAttribute(name);
    if (v == null) return fallback;
    final hex = v.replaceFirst('#', '');
    return int.tryParse(hex, radix: 16) ?? fallback;
  }

  /// [Color] 屬性：8 碼含 alpha；6 碼補不透明。可含或不含前導 `#`。
  static Color color(XmlElement el, String name, Color fallback) {
    final v = el.getAttribute(name);
    if (v == null) return fallback;
    final hex = v.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return fallback;
    if (hex.length == 8) return Color(value);
    if (hex.length == 6) return Color(0xFF000000 | value);
    return fallback;
  }
}
