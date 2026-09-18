import 'package:flutter/foundation.dart';

import 'ui_xaml_assets.dart';
import 'ui_xaml_loader.dart';
import 'ui_xaml_registry.dart';

/// 一個畫面的 XAML 設定容器：載入、快取、變更通知。
///
/// 十幾個畫面各自抄一份「static config + isLoaded + revision + reload」的樣板，
/// 差別只有型別；抄到第三份就會有人漏掉 `revision.value++`，於是改了 XAML 卻不
/// 重繪。這裡把那份樣板收成一個泛型物件。
///
/// [build] 收到的是完整的 [UiXamlResult]（含 tier），所以畫面可以在還沒遷移時
/// 從舊 XML 取值，遷移後改讀 document，兩種情況共用同一個 holder。
class UiXamlSpecHolder<T> {
  UiXamlSpecHolder({
    required this.view,
    required T initial,
    required this.build,
  }) : _value = initial;

  final UiXamlView view;

  /// 由載入結果建出 spec。任何解析失敗都應在此回傳可用的預設值，而不是丟例外。
  final T Function(UiXamlResult result, UiXamlAssets assets) build;

  T _value;
  bool _loaded = false;
  UiXamlTier _tier = UiXamlTier.dartDefault;

  /// 目前生效的設定。尚未載入時是建構時給的預設值 —— 畫面因此永遠有東西可畫，
  /// 不需要在每個 widget 裡處理「還沒載好」的狀態。
  T get value => _value;

  bool get isLoaded => _loaded;

  /// 目前這個畫面實際吃到哪一層設定，供 debug 顯示。
  UiXamlTier get tier => _tier;

  /// 重載後遞增；widget 以 [ValueListenableBuilder] 監聽即可即時預覽。
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await reload();
  }

  Future<void> reload() async {
    final result = await UiXamlLoader.load(view);
    _tier = result.tier;
    _value = build(result, UiXamlLoader.assets);
    _loaded = true;
    revision.value++;
  }

  @visibleForTesting
  void resetForTest(T initial) {
    _value = initial;
    _loaded = false;
    _tier = UiXamlTier.dartDefault;
  }
}
