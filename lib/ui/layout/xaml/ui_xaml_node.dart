import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

/// XAML 子集允許的節點。
///
/// 白名單而非黑名單：這份 XAML 是要交給非程式人員改的，容許未知節點等於容許
/// 「改了沒反應而且不知道為什麼」。不在表內的節點會記一行 debug warning 後忽略，
/// 正式版不會因此崩潰（見 [UiXamlNode.parse]）。
const Set<String> kUiXamlNodes = {
  'Background',
  'Stack',
  'Row',
  'Column',
  'Text',
  'Image',
  'Icon',
  'TextField',
  'Button',
  'ProgressBar',
  'List',
  'InkFadeRect',
  'Spacer',
  'Divider',
};

/// 屬性值的 token 參照語法：`width="{fieldWidth}"`。
///
/// 存在的理由是規格裡「帳號與密碼必須引用同一個 fieldWidth token」這類要求 ——
/// 兩個欄位各寫一次 390 就是等著哪天只改到一個。
final RegExp _tokenRef = RegExp(r'^\{([A-Za-z_][A-Za-z0-9_]*)\}$');

/// 解析期間累積的警告；載入完成後由 loader 一次印出。
class UiXamlDiagnostics {
  final List<String> messages = [];

  void warn(String message) => messages.add(message);

  bool get isEmpty => messages.isEmpty;
}

/// 已解析、且只含白名單節點的一個 XAML 節點。
///
/// 所有取值方法都是「取不到或解析失敗就回傳 fallback」，並可給 min/max 夾住 ——
/// 外部配置的職責是調整，不是讓畫面壞掉。一個手滑打成 `height="3200"` 的
/// loading bar 應該被夾回 36，而不是撐爆版面。
@immutable
class UiXamlNode {
  const UiXamlNode({
    required this.type,
    required this.attributes,
    required this.children,
    this.tokens = const {},
    this.diagnostics,
  });

  final String type;
  final Map<String, String> attributes;
  final List<UiXamlNode> children;

  /// theme token 表；屬性寫 `{name}` 時由此解析。
  final Map<String, String> tokens;

  final UiXamlDiagnostics? diagnostics;

  String get id => attributes['id'] ?? '';

  /// 解析一棵 XML 子樹，濾掉白名單以外的節點。
  static UiXamlNode? parse(
    XmlElement element, {
    Map<String, String> tokens = const {},
    UiXamlDiagnostics? diagnostics,
    bool isRoot = false,
  }) {
    if (!isRoot && !kUiXamlNodes.contains(element.name.local)) {
      diagnostics?.warn('未知節點 <${element.name.local}>，已忽略');
      return null;
    }
    final children = <UiXamlNode>[];
    for (final child in element.childElements) {
      final node = parse(child, tokens: tokens, diagnostics: diagnostics);
      if (node != null) children.add(node);
    }
    return UiXamlNode(
      type: element.name.local,
      attributes: {
        for (final attr in element.attributes) attr.name.local: attr.value,
      },
      children: children,
      tokens: tokens,
      diagnostics: diagnostics,
    );
  }

  /// 取原始字串屬性，先解開 `{token}` 參照。
  String? raw(String name) {
    final value = attributes[name];
    if (value == null) return null;
    final match = _tokenRef.firstMatch(value.trim());
    if (match == null) return value;
    final token = tokens[match.group(1)];
    if (token == null) {
      diagnostics?.warn('<$type $name="$value"> 參照了不存在的 token');
      return null;
    }
    return token;
  }

  String s(String name, String fallback) {
    final value = raw(name);
    return (value == null || value.isEmpty) ? fallback : value;
  }

  double d(String name, double fallback, {double? min, double? max}) {
    final value = raw(name);
    if (value == null) return _clampD(fallback, min, max);
    final parsed = double.tryParse(value);
    if (parsed == null) {
      diagnostics?.warn('<$type $name="$value"> 不是數字，改用 $fallback');
      return _clampD(fallback, min, max);
    }
    final clamped = _clampD(parsed, min, max);
    if (clamped != parsed) {
      diagnostics?.warn('<$type $name="$value"> 超出範圍，夾成 $clamped');
    }
    return clamped;
  }

  int i(String name, int fallback, {int? min, int? max}) =>
      d(name, fallback.toDouble(),
              min: min?.toDouble(), max: max?.toDouble())
          .round();

  bool b(String name, bool fallback) {
    final value = raw(name)?.toLowerCase();
    if (value == null) return fallback;
    if (value == 'true' || value == '1') return true;
    if (value == 'false' || value == '0') return false;
    diagnostics?.warn('<$type $name="$value"> 不是布林值，改用 $fallback');
    return fallback;
  }

  /// 顏色：8 碼含 alpha、6 碼補不透明，可含或不含前導 `#`。
  Color color(String name, Color fallback) {
    final value = raw(name);
    if (value == null) return fallback;
    final hex = value.replaceFirst('#', '').trim();
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null || (hex.length != 6 && hex.length != 8)) {
      diagnostics?.warn('<$type $name="$value"> 不是合法顏色，改用預設');
      return fallback;
    }
    return Color(hex.length == 8 ? parsed : 0xFF000000 | parsed);
  }

  /// 第一個 [type] 相符的子節點（不遞迴）。
  UiXamlNode? child(String type) {
    for (final node in children) {
      if (node.type == type) return node;
    }
    return null;
  }

  /// 整棵子樹中 id 相符的節點。
  UiXamlNode? findById(String value) {
    if (id == value) return this;
    for (final node in children) {
      final found = node.findById(value);
      if (found != null) return found;
    }
    return null;
  }

  static double _clampD(double value, double? min, double? max) {
    var result = value;
    if (min != null && result < min) result = min;
    if (max != null && result > max) result = max;
    return result;
  }
}

/// 一個畫面的根節點。設計座標固定 1920×1080（見接手計畫 §4）。
@immutable
class UiXamlDocument {
  const UiXamlDocument({
    required this.id,
    required this.designWidth,
    required this.designHeight,
    required this.root,
    required this.source,
  });

  final String id;
  final double designWidth;
  final double designHeight;
  final UiXamlNode root;

  /// 實際載到的檔案路徑，供 debug log 說明「這畫面現在吃的是哪一份」。
  final String source;

  /// 找子節點。
  ///
  /// 刻意跳過根節點：`<UiView id="account">` 的 id 是**畫面代號**，與節點 id 是
  /// 兩個命名空間。若一併比對，`findById('account')` 會先命中根節點，回傳一個
  /// 沒有 width/centerX 的東西，於是整欄悄悄退回預設值 —— 帳號欄與密碼欄的
  /// 預設值剛好相同，連「兩欄等寬」的驗收都會照樣通過。
  UiXamlNode? findById(String value) {
    for (final node in root.children) {
      final found = node.findById(value);
      if (found != null) return found;
    }
    return null;
  }
}
