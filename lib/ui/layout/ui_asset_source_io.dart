import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};
final Map<String, Timer> _debouncers = {};
final Map<String, List<void Function()>> _listeners = {};

/// Debug 模式下從專案根目錄讀取 assets 原始檔（路徑與 pubspec 一致）。
Future<String?> readDebugAssetFile(String assetPath) async {
  if (!kDebugMode) {
    return null;
  }
  final file = File(assetPath);
  if (!file.existsSync()) {
    return null;
  }
  try {
    return file.readAsStringSync();
  } catch (_) {
    return null;
  }
}

/// 監聽 XML/XAML 存檔；編輯器常觸發多次 modify，以 debounce 合併。
///
/// 同一個檔可以有多個監聽者，全部都會被通知。遷移期間這是必要的：舊的
/// `CharCreateUiDevWatcher` 與新的 `UiXamlDevWatcher` 都會盯著
/// `assets/ui/layouts/*.xml`，若後註冊的取代先註冊的，其中一邊的即時預覽會安靜
/// 地失效 —— 沒有錯誤訊息，只是存檔之後畫面不動。
void watchDebugAssetFile(String assetPath, void Function() onChanged) {
  if (!kDebugMode) {
    return;
  }
  final file = File(assetPath);
  if (!file.existsSync()) {
    return;
  }
  _listeners.putIfAbsent(assetPath, () => []).add(onChanged);
  if (_watchers.containsKey(assetPath)) {
    return; // 這個檔已經在監看了，只是多一個聽眾。
  }
  _watchers[assetPath] = file.watch().listen((event) {
    if (event.type != FileSystemEvent.modify) {
      return;
    }
    _debouncers[assetPath]?.cancel();
    _debouncers[assetPath] = Timer(const Duration(milliseconds: 250), () {
      for (final listener in List.of(_listeners[assetPath] ?? const [])) {
        listener();
      }
    });
  });
}

void disposeDebugAssetWatchers() {
  for (final sub in _watchers.values) {
    sub.cancel();
  }
  _watchers.clear();
  for (final timer in _debouncers.values) {
    timer.cancel();
  }
  _debouncers.clear();
  _listeners.clear();
}
