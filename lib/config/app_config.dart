import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App 全域設定（由 assets/data/app_config.json 載入）。
///
/// 目前只含 log 開關；之後可擴充其他全域旗標。
class AppConfig {
  const AppConfig({required this.logEnabled, required this.logTags});

  /// log 總開關。
  final bool logEnabled;

  /// 各分類（tag）細開關；未列出的 tag 在總開關開啟時預設為 true。
  final Map<String, bool> logTags;

  /// 指定 tag 是否要輸出 log：總開關開啟，且該 tag 未被明確關閉。
  bool isTagEnabled(String tag) => logEnabled && (logTags[tag] ?? true);

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final log = json['log'] as Map<String, dynamic>? ?? const {};
    final tags = log['tags'] as Map<String, dynamic>? ?? const {};
    return AppConfig(
      logEnabled: log['enabled'] as bool? ?? false,
      logTags: tags.map((k, v) => MapEntry(k, v as bool? ?? true)),
    );
  }

  /// 讀取 assets 失敗時的 fallback：debug build 預設開 log，release 關。
  factory AppConfig.fallback() =>
      AppConfig(logEnabled: kDebugMode, logTags: const {});
}

/// 載入並快取 [AppConfig]。
///
/// 提供**可同步讀取**的 [current]，供 onTapDown 等同步流程使用
/// （log 呼叫不能每次 await）。請於 `main()` 啟動時呼叫 [load] 一次。
class AppConfigLoader {
  AppConfigLoader._();

  static const _assetPath = 'assets/data/app_config.json';

  static AppConfig _current = AppConfig.fallback();
  static bool _loaded = false;

  /// 目前設定（未載入前回 fallback）。
  static AppConfig get current => _current;

  static Future<AppConfig> load() async {
    if (_loaded) return _current;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      _current = AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _current = AppConfig.fallback();
    }
    _loaded = true;
    return _current;
  }
}
