import 'package:flutter/foundation.dart';

import 'specs/account_ui_spec.dart';
import 'specs/loading_ui_spec.dart';
import 'specs/server_select_ui_spec.dart';
import 'ui_xaml_dev_watcher.dart';
import 'ui_xaml_loader.dart';
import 'ui_xaml_spec_holder.dart';

/// 所有已遷移到 XAML 的畫面設定的集中啟動點。
///
/// 每遷移一個畫面就在 [holders] 加一筆，啟動預載與 debug 即時預覽就同時生效。
/// 讓各畫面自己在 main() 裡註冊的話，遲早會有一頁漏掉 —— 症狀是「別頁都能即時
/// 預覽，就這頁要重開」，而且不會有任何錯誤訊息。
abstract final class UiXamlBootstrap {
  static final List<UiXamlSpecHolder<Object?>> holders = [
    LoadingUiSpec.holder,
    AccountUiSpec.holder,
    ServerSelectUiSpec.holder,
  ];

  /// App 啟動時呼叫一次：載入 theme/assets 與所有畫面設定。
  ///
  /// 在 `runApp` 之前做完，第一幀就是正確的版面，不會先閃一下 Dart 預設值。
  static Future<void> ensureLoaded() async {
    await UiXamlLoader.ensureShared();
    for (final holder in holders) {
      await holder.ensureLoaded();
    }
    if (kDebugMode) {
      UiXamlDevWatcher.addListener(reloadAll);
      UiXamlDevWatcher.ensureStarted();
    }
  }

  /// 任一 XAML 存檔後重載全部 —— theme token 是跨畫面的，只重載被改的那頁
  /// 會讓其他頁停在舊 token 上。
  static Future<void> reloadAll() async {
    await UiXamlLoader.reloadShared();
    for (final holder in holders) {
      await holder.reload();
    }
  }
}
