import 'package:flutter/material.dart';

import '../ui/layout/char_create/char_create_ui_assets.dart';

/// 靈根展示資料（與後端 AttributeTemplate 0~7 對齊）。
class SpiritRootDetail {
  const SpiritRootDetail({
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.color,
  });

  final String name;
  final String description;
  final String iconAsset;
  final Color color;
}

/// 創角模板常數（與後端 template 對齊）。
abstract final class CharCreateTemplate {
  static const int baseIntel = 10;
  static const int baseSpirit = 10;
  static const int baseAgility = 10;
  static const int baseConstitution = 10;
  static const int bonusPool = 8;

  static const List<String> attributeNames = [
    '金',
    '木',
    '水',
    '火',
    '土',
    '風',
    '雷',
    '幻',
  ];

  static const List<SpiritRootDetail> spiritRootDetails = [
    SpiritRootDetail(
      name: '金靈根',
      description: '鋒銳剛猛，攻擊兼備',
      iconAsset: CharCreateUiAssets.attrMetal,
      color: Color(0xFFE8C547),
    ),
    SpiritRootDetail(
      name: '木靈根',
      description: '生機盎然，治癒輔助',
      iconAsset: CharCreateUiAssets.attrWood,
      color: Color(0xFF5CB85C),
    ),
    SpiritRootDetail(
      name: '水靈根',
      description: '溫柔流轉，控場大能',
      iconAsset: CharCreateUiAssets.attrWater,
      color: Color(0xFF4A9FD8),
    ),
    SpiritRootDetail(
      name: '火靈根',
      description: '爆發熾烈，毀滅之力',
      iconAsset: CharCreateUiAssets.attrFire,
      color: Color(0xFFE74C3C),
    ),
    SpiritRootDetail(
      name: '土靈根',
      description: '穩重厚實，防禦無雙',
      iconAsset: CharCreateUiAssets.attrEarth,
      color: Color(0xFF8B6914),
    ),
    SpiritRootDetail(
      name: '風靈根',
      description: '極速飄逸，身法靈活',
      iconAsset: CharCreateUiAssets.attrWind,
      color: Color(0xFF7EC8E3),
    ),
    SpiritRootDetail(
      name: '雷靈根',
      description: '狂暴麻痺，瞬間爆發',
      iconAsset: CharCreateUiAssets.attrThunder,
      color: Color(0xFF9B59B6),
    ),
    SpiritRootDetail(
      name: '幻靈根',
      description: '虛實難測，幻境主宰',
      iconAsset: CharCreateUiAssets.attrIllusion,
      color: Color(0xFFD68FD6),
    ),
  ];

  /// UI statKey → 後端 / createCharacter 參數名稱。
  static const Map<String, String> statBackendFields = {
    'intel': 'statsIntel',
    'spirit': 'statsSpirit',
    'agility': 'statsAgility',
    'constitution': 'statsConstitution',
  };

  static const List<Color> attributeColors = [
    Color(0xFFE8C547),
    Color(0xFF5CB85C),
    Color(0xFF4A9FD8),
    Color(0xFFE74C3C),
    Color(0xFF8B6914),
    Color(0xFF7EC8E3),
    Color(0xFF9B59B6),
    Color(0xFFD68FD6),
  ];
}
