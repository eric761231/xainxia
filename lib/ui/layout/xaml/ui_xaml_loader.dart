import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import '../ui_asset_source_stub.dart'
    if (dart.library.io) '../ui_asset_source_io.dart';
import 'ui_xaml_assets.dart';
import 'ui_xaml_node.dart';
import 'ui_xaml_registry.dart';
import 'ui_xaml_theme.dart';

/// 一個畫面實際載到哪一層。
///
/// 遷移是逐頁進行的，所以同一時間不同畫面會停在不同層；把它做成明確的列舉
/// （而不是「document 是不是 null」）才能在 log 與測試裡直接看出某頁走到哪。
enum UiXamlTier {
  /// 讀到新的 `.xaml`。
  xaml,

  /// 新檔不存在，退回遷移期間的舊 `.xml`，由該畫面原本的 loader 解析。
  legacyXml,

  /// 兩者皆無，使用 Dart 內建預設值。
  dartDefault,
}

/// 載入結果。
@immutable
class UiXamlResult {
  const UiXamlResult({
    required this.tier,
    required this.view,
    this.document,
    this.legacyXml,
  });

  final UiXamlTier tier;
  final UiXamlView view;

  /// [UiXamlTier.xaml] 時才有值。
  final UiXamlDocument? document;

  /// [UiXamlTier.legacyXml] 時才有值：舊 XML 的原始字串。
  final String? legacyXml;
}

/// XAML 載入器。
///
/// 三段式 fallback：`.xaml` → 舊 `.xml` → Dart 預設。任何一層失敗都只是往下掉，
/// 不會丟例外 —— 外部配置檔壞掉時應該是「畫面退回預設樣子」，不是黑屏。
///
/// 不使用 runtime reflection：節點與屬性都由各畫面的 spec 明確讀取。反射能少寫
/// 一些程式，但也讓「XAML 寫錯欄位名」從編譯期問題變成線上問題。
abstract final class UiXamlLoader {
  static UiXamlTheme _theme = UiXamlTheme.fallback;
  static UiXamlAssets _assets = UiXamlAssets.fallback;
  static bool _sharedLoaded = false;

  static UiXamlTheme get theme => _theme;
  static UiXamlAssets get assets => _assets;
  static bool get sharedLoaded => _sharedLoaded;

  /// 載入 theme 與 assets manifest。各畫面載入前會自動確保已執行。
  static Future<void> ensureShared() async {
    if (_sharedLoaded) return;
    await reloadShared();
  }

  static Future<void> reloadShared() async {
    final diagnostics = UiXamlDiagnostics();
    final themeXml = await _read(UiXamlRegistry.theme);
    _theme = themeXml == null
        ? UiXamlTheme.fallback
        : UiXamlTheme.parse(themeXml, diagnostics: diagnostics);
    final assetsXml = await _read(UiXamlRegistry.assets);
    _assets = assetsXml == null
        ? UiXamlAssets.fallback
        : UiXamlAssets.parse(assetsXml, diagnostics: diagnostics);
    _sharedLoaded = true;
    _report('theme/assets', diagnostics);
  }

  /// 依 [view] 取得目前應使用的設定來源。
  static Future<UiXamlResult> load(UiXamlView view) async {
    await ensureShared();

    final raw = await _read(view.xaml);
    if (raw != null) {
      final diagnostics = UiXamlDiagnostics();
      final document = _parse(view, raw, diagnostics);
      _report(view.xaml, diagnostics);
      if (document != null) {
        return UiXamlResult(
          tier: UiXamlTier.xaml,
          view: view,
          document: document,
        );
      }
      // 解析失敗：不要停在這裡，繼續往舊檔退，否則一個手滑的 XAML 會讓整頁
      // 連舊設定都吃不到。
    }

    final legacy = view.legacyXml;
    if (legacy != null) {
      final rawLegacy = await _read(legacy);
      if (rawLegacy != null) {
        return UiXamlResult(
          tier: UiXamlTier.legacyXml,
          view: view,
          legacyXml: rawLegacy,
        );
      }
    }

    return UiXamlResult(tier: UiXamlTier.dartDefault, view: view);
  }

  /// debug 版優先讀專案內的原始檔（存檔即可預覽），release 走 rootBundle。
  static Future<String?> _read(String assetPath) async {
    try {
      final fromDisk = await readDebugAssetFile(assetPath);
      if (fromDisk != null) return fromDisk;
    } catch (_) {
      // 讀不到磁碟檔就當作沒有，改走 bundle。
    }
    try {
      return await rootBundle.loadString(assetPath);
    } catch (_) {
      return null;
    }
  }

  static UiXamlDocument? _parse(
    UiXamlView view,
    String raw,
    UiXamlDiagnostics diagnostics,
  ) {
    try {
      final root = XmlDocument.parse(raw).rootElement;
      if (root.name.local != 'UiView') {
        diagnostics.warn('根節點必須是 <UiView>，實際是 <${root.name.local}>');
        return null;
      }
      final declaredId = root.getAttribute('id');
      if (declaredId != null && declaredId != view.id) {
        // 只是提醒：檔名與 id 對不上通常代表複製貼上時忘了改。
        diagnostics.warn('id="$declaredId" 與登記的 "${view.id}" 不符');
      }
      final node = UiXamlNode.parse(
        root,
        tokens: _theme.values,
        diagnostics: diagnostics,
        isRoot: true,
      );
      if (node == null) return null;
      return UiXamlDocument(
        id: view.id,
        // 設計座標固定 1920×1080；允許在檔案裡宣告，但夾在合理範圍內，
        // 免得一個打錯的 designWidth 讓整頁縮成一點。
        designWidth: node.d('designWidth', 1920, min: 320, max: 7680),
        designHeight: node.d('designHeight', 1080, min: 240, max: 4320),
        root: node,
        source: view.xaml,
      );
    } catch (e) {
      diagnostics.warn('XML 解析失敗：$e');
      return null;
    }
  }

  static void _report(String label, UiXamlDiagnostics diagnostics) {
    if (!kDebugMode || diagnostics.isEmpty) return;
    for (final message in diagnostics.messages) {
      debugPrint('UiXaml[$label] $message');
    }
  }

  /// 測試用：清掉共用設定，讓下一次 load 重讀。
  @visibleForTesting
  static void resetForTest() {
    _theme = UiXamlTheme.fallback;
    _assets = UiXamlAssets.fallback;
    _sharedLoaded = false;
  }
}
