/// 角色選擇 UI 素材路徑（複用 create_char 資料夾素材）。
abstract final class CharSelectUiAssets {
  // 全螢幕背景
  static const String bg = 'assets/ui/create_char/char_bg.png';

  // 角色立繪（中央欄 + 左欄縮圖）
  static const String charMale = 'assets/ui/create_char/char_male.png';
  static const String charFemale = 'assets/ui/create_char/char_female.png';

  // 靈根 icon（0=金 1=木 2=水 3=火 4=土 5=風 6=雷 7=幻）
  static const String attrMetal = 'assets/ui/create_char/attr_metal.png';
  static const String attrWood = 'assets/ui/create_char/attr_wood.png';
  static const String attrWater = 'assets/ui/create_char/attr_water.png';
  static const String attrFire = 'assets/ui/create_char/attr_fire.png';
  static const String attrEarth = 'assets/ui/create_char/attr_earth.png';
  static const String attrWind = 'assets/ui/create_char/attr_wind.png';
  static const String attrThunder = 'assets/ui/create_char/attr_thunder.png';
  static const String attrIllusion = 'assets/ui/create_char/attr_illusion.png';

  // 按鈕 / 標題 label 底圖
  static const String cloudLabel04 = 'assets/ui/create_char/cloud_label04.png';
  static const String cloudLabel05 = 'assets/ui/create_char/cloud_label05.png';
  static const String inkBtn04 = 'assets/ui/create_char/ink_btn04.png';

  // 返回按鈕
  static const String backIcon = 'assets/ui/create_char/back_icon.png';
  static const String backIconHover = 'assets/ui/create_char/back_icon_hover.png';
  static const String backIconPressed = 'assets/ui/create_char/back_icon_pressed.png';

  /// 依 attribute index 回傳對應靈根 icon 路徑。
  static String attrIcon(int attribute) {
    return switch (attribute) {
      0 => attrMetal,
      1 => attrWood,
      2 => attrWater,
      3 => attrFire,
      4 => attrEarth,
      5 => attrWind,
      6 => attrThunder,
      _ => attrIllusion,
    };
  }

  /// 依 sex 回傳對應立繪路徑（0=男 1=女）。
  static String portrait(int sex) =>
      sex == 0 ? charMale : charFemale;
}
