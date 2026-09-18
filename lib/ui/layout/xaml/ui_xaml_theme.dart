import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import 'ui_xaml_node.dart';

/// `theme.xaml` 的 token 表：顏色、字級、間距、陰影、淡出透明度。
///
/// 畫面的 XAML 以 `{tokenName}` 參照這裡的值。把數字集中一處不只是為了少打字 ——
/// 「帳號與密碼欄位等寬」這種規格若靠兩邊各寫一次 390 來維持，遲早會有人只改一邊。
///
/// 解析不到就整份退回 [fallback]；缺一個 token 不會讓畫面消失，只會讓那個屬性
/// 退回它自己的 Dart 預設值。
@immutable
class UiXamlTheme {
  const UiXamlTheme({required this.values});

  /// token 名 → 原始字串值（顏色是 hex、尺寸是數字）。
  final Map<String, String> values;

  static const UiXamlTheme fallback = UiXamlTheme(values: {});

  bool get isEmpty => values.isEmpty;

  String? operator [](String token) => values[token];

  double size(String token, double fallback) {
    final raw = values[token];
    if (raw == null) return fallback;
    return double.tryParse(raw) ?? fallback;
  }

  Color color(String token, Color fallback) {
    final raw = values[token];
    if (raw == null) return fallback;
    final hex = raw.replaceFirst('#', '').trim();
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null || (hex.length != 6 && hex.length != 8)) return fallback;
    return Color(hex.length == 8 ? parsed : 0xFF000000 | parsed);
  }

  /// 解析 `<Theme><Color id="ink" value="#1A1B1E"/><Size id="fieldWidth" value="390"/></Theme>`。
  ///
  /// 節點名（Color/Size/Opacity/...）只是給人看的分類，值一律以字串收進同一張表；
  /// 真正的型別在使用端決定（`size()` 或 `color()`）。這樣新增一類 token 不必改
  /// 解析器。
  static UiXamlTheme parse(String xml, {UiXamlDiagnostics? diagnostics}) {
    try {
      final root = XmlDocument.parse(xml).rootElement;
      final values = <String, String>{};
      for (final el in root.childElements) {
        final id = el.getAttribute('id');
        final value = el.getAttribute('value');
        if (id == null || id.isEmpty || value == null) {
          diagnostics?.warn('theme.xaml 的 <${el.name.local}> 缺 id 或 value，已忽略');
          continue;
        }
        if (values.containsKey(id)) {
          diagnostics?.warn('theme.xaml 有重複的 token "$id"，採用後者');
        }
        values[id] = value;
      }
      return UiXamlTheme(values: values);
    } catch (e) {
      diagnostics?.warn('theme.xaml 解析失敗（$e），全部 token 退回 Dart 預設');
      return fallback;
    }
  }
}
