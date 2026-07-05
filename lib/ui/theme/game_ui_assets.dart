import '../../models/char_create_template.dart';

/// 遊戲 UI 素材路徑（美術資源位於 assets/ui/、assets/characters/）。
abstract final class GameUiAssets {
  static const String dialogMessageBg =
      'assets/ui/common/dialog_message_bg.png';

  /// 創角立繪：create_{m|f}_{attribute}.png，attribute 0~7
  static String createCharPreview({required int sex, required int attribute}) {
    final gender = sex == 0 ? 'm' : 'f';
    return 'assets/characters/create_${gender}_$attribute.png';
  }

  static String attributeLabel(int attribute) {
    if (attribute < 0 ||
        attribute >= CharCreateTemplate.attributeNames.length) {
      return '?';
    }
    return CharCreateTemplate.attributeNames[attribute];
  }
}
