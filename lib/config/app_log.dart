import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// 統一 log 出口：依 app_config.json 的 log 開關決定是否輸出。
///
/// 用法：`AppLog.d('ISO-TAP', 'onTapDown …')`
/// 會輸出 `[ISO-TAP] onTapDown …`，且僅在該 tag 啟用時才輸出。
class AppLog {
  AppLog._();

  static void d(String tag, String message) {
    if (AppConfigLoader.current.isTagEnabled(tag)) {
      debugPrint('[$tag] $message');
    }
  }
}
