/// 全專案 UI 的 XAML 登記表。
///
/// 一個畫面一筆 [UiXamlView]，記住三件事：要載哪個 `.xaml`、遷移期間退回哪個舊
/// `.xml`、以及 debug 監看要盯哪些檔。新增畫面只動這張表，loader 與 dev watcher
/// 都從這裡讀 —— 兩份清單各自維護正是「改了 XAML 卻沒有即時預覽」的來源。
library;

/// 單一畫面的 XAML 來源設定。
class UiXamlView {
  const UiXamlView({
    required this.id,
    required this.xaml,
    this.legacyXml,
  });

  /// 畫面代號，同時是 `<UiView id="...">` 應有的值。
  final String id;

  /// 目標 `.xaml` 路徑（assets 相對路徑，與 pubspec 一致）。
  final String xaml;

  /// 遷移期間的舊 `.xml`；該畫面尚未有舊檔時為 null。
  ///
  /// 載入順序是 `.xaml` → 這個 → Dart 內建預設。舊檔在逐頁遷移完成後移除，
  /// 到時把這個欄位拿掉即可，不必改 loader。
  final String? legacyXml;

  /// debug 監看要盯的所有檔案。
  List<String> get watchPaths => [xaml, ?legacyXml];
}

abstract final class UiXamlRegistry {
  static const theme = 'assets/ui/xaml/theme.xaml';
  static const assets = 'assets/ui/xaml/assets.xaml';

  static const loading = UiXamlView(
    id: 'loading',
    xaml: 'assets/ui/xaml/loading.xaml',
  );
  static const account = UiXamlView(
    id: 'account',
    xaml: 'assets/ui/xaml/account.xaml',
  );
  static const serverSelect = UiXamlView(
    id: 'serverSelect',
    xaml: 'assets/ui/xaml/server_select.xaml',
  );
  static const messageDialog = UiXamlView(
    id: 'messageDialog',
    xaml: 'assets/ui/xaml/message_dialog.xaml',
  );
  static const characterSelect = UiXamlView(
    id: 'characterSelect',
    xaml: 'assets/ui/xaml/character_select.xaml',
    legacyXml: 'assets/ui/layouts/char_select_layout.xml',
  );
  static const characterCreate = UiXamlView(
    id: 'characterCreate',
    xaml: 'assets/ui/xaml/character_create.xaml',
    legacyXml: 'assets/ui/layouts/char_create_layout.xml',
  );
  static const gameHud = UiXamlView(
    id: 'gameHud',
    xaml: 'assets/ui/xaml/game_hud.xaml',
  );
  static const inventory = UiXamlView(
    id: 'inventory',
    xaml: 'assets/ui/xaml/inventory.xaml',
  );
  static const cultivation = UiXamlView(
    id: 'cultivation',
    xaml: 'assets/ui/xaml/cultivation.xaml',
  );
  static const social = UiXamlView(
    id: 'social',
    xaml: 'assets/ui/xaml/social.xaml',
  );
  static const decor = UiXamlView(
    id: 'decor',
    xaml: 'assets/ui/xaml/decor.xaml',
  );
  static const gm = UiXamlView(
    id: 'gm',
    xaml: 'assets/ui/xaml/gm.xaml',
  );
  static const portraitAnchors = UiXamlView(
    id: 'portraitAnchors',
    xaml: 'assets/ui/xaml/portrait_anchors.xaml',
  );

  static const List<UiXamlView> views = [
    loading,
    account,
    serverSelect,
    messageDialog,
    characterSelect,
    characterCreate,
    gameHud,
    inventory,
    cultivation,
    social,
    decor,
    gm,
    portraitAnchors,
  ];

  /// debug 即時預覽要監看的全部檔案（含 theme / assets 與各畫面的新舊檔）。
  static List<String> get watchPaths => [
        theme,
        assets,
        for (final view in views) ...view.watchPaths,
      ];
}
