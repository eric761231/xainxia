/// 全專案 UI 布局 XML 登記表；新增畫面時在此加入 path，Dev 監聽會一併覆蓋。
abstract final class UiLayoutXmlRegistry {
  static const createCharLayout = 'assets/ui/layouts/char_create_layout.xml';
  static const charSelectLayout = 'assets/ui/layouts/char_select_layout.xml';

  /// 所有可即時預覽的布局 XML（assets 相對路徑）。
  static const List<String> all = [
    createCharLayout,
    charSelectLayout,
  ];
}
