import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

final Map<String, StreamSubscription<FileSystemEvent>> _watchers = {};
final Map<String, Timer> _debouncers = {};

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

/// 監聽 XML 存檔；編輯器常觸發多次 modify，以 debounce 合併。
void watchDebugAssetFile(String assetPath, void Function() onChanged) {
  if (!kDebugMode) {
    return;
  }
  final file = File(assetPath);
  if (!file.existsSync()) {
    return;
  }
  _watchers[assetPath]?.cancel();
  _watchers[assetPath] = file.watch().listen((event) {
    if (event.type != FileSystemEvent.modify) {
      return;
    }
    _debouncers[assetPath]?.cancel();
    _debouncers[assetPath] = Timer(const Duration(milliseconds: 250), onChanged);
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
}
