import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ui_asset_source_stub.dart'
    if (dart.library.io) '../ui_asset_source_io.dart';
import 'ui_xaml_registry.dart';

/// Debug 模式下監看 [UiXamlRegistry.watchPaths] 內所有檔案，存檔後重載。
///
/// 取代原本只綁創角／選角兩頁的 `CharCreateUiDevWatcher`。監看清單直接取自
/// registry，所以新增畫面只要登記一筆就有即時預覽，不會發生「加了 XAML 但忘了
/// 加進 watcher」。
///
/// Release 版的 [watchDebugAssetFile] 是 no-op（見 ui_asset_source_stub.dart），
/// 正式版不依賴檔案系統。
abstract final class UiXamlDevWatcher {
  static bool _started = false;

  /// 檔案變動時要做的事；由 app 啟動時註冊（通常是重載各畫面 spec）。
  static final List<Future<void> Function()> _listeners = [];

  /// 註冊一個重載回呼。重複註冊同一個函式沒有意義，但也無害。
  static void addListener(Future<void> Function() onChanged) {
    _listeners.add(onChanged);
  }

  static void ensureStarted() {
    if (!kDebugMode || _started) return;
    _started = true;
    for (final path in UiXamlRegistry.watchPaths) {
      watchDebugAssetFile(path, _notify);
    }
    debugPrint(
      'UiXamlDevWatcher：已啟動 XAML 即時預覽'
      '（${UiXamlRegistry.watchPaths.length} 個檔案）',
    );
  }

  static void _notify() {
    for (final listener in _listeners) {
      unawaited(listener());
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _started = false;
    _listeners.clear();
  }
}
