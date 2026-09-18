import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'ui_xaml_node.dart';

/// `assets.xaml` 的 id → 圖片路徑對照表。
///
/// 畫面 XAML 只寫 `asset="loginFlowBg"`，不寫路徑。原因是素材換檔名、換目錄是
/// 常態，而路徑散在十幾個 Dart 檔裡時，漏改的那一個會在 release 才變成一張白圖。
///
/// 找不到 id 時回傳 null 而不是丟例外 —— 呼叫端據此退回自己的 Dart 預設素材。
@immutable
class UiXamlAssets {
  const UiXamlAssets({required this.paths});

  final Map<String, String> paths;

  static const UiXamlAssets fallback = UiXamlAssets(paths: {});

  bool get isEmpty => paths.isEmpty;

  /// 取素材路徑；未登記時回傳 [fallbackPath]。
  String? path(String id, {String? fallbackPath}) => paths[id] ?? fallbackPath;

  /// 解析 `<UiAssets><Asset id="loginFlowBg" path="assets/..."/></UiAssets>`。
  static UiXamlAssets parse(String xml, {UiXamlDiagnostics? diagnostics}) {
    try {
      final root = XmlDocument.parse(xml).rootElement;
      final paths = <String, String>{};
      for (final el in root.childElements) {
        if (el.name.local != 'Asset') {
          diagnostics?.warn('assets.xaml 出現非 <Asset> 的 <${el.name.local}>，已忽略');
          continue;
        }
        final id = el.getAttribute('id');
        final path = el.getAttribute('path');
        if (id == null || id.isEmpty || path == null || path.isEmpty) {
          diagnostics?.warn('assets.xaml 的 <Asset> 缺 id 或 path，已忽略');
          continue;
        }
        if (paths.containsKey(id)) {
          diagnostics?.warn('assets.xaml 有重複的 asset id "$id"，採用後者');
        }
        paths[id] = path;
      }
      return UiXamlAssets(paths: paths);
    } catch (e) {
      diagnostics?.warn('assets.xaml 解析失敗（$e），素材 id 全部退回 Dart 預設');
      return fallback;
    }
  }
}
