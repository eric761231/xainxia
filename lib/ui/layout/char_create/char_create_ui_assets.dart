import '../../theme/game_ui_assets.dart';
import 'char_create_ui_loader.dart';

/// 切圖路徑（`assets/ui/char_create/`）。
///
/// 顯示尺寸、位置見 [char_create_layout.xml] → [CharCreateUiSpec]。
/// 登入過場預載清單見 [allPreloadPaths]。
abstract final class CharCreateUiAssets {
  /// 布局 XML（由 [CharCreateUiLoader] 讀取，非 PNG）。
  static const String layoutXml = CharCreateUiLoader.assetPath;

  // ── L1 全螢幕背景 ─────────────────────────────
  static const String bg = 'assets/ui/char_create/char_bg.png';

  // ── L3 左欄靈根 icon ──────────────────────────
  static const String attrMetal = 'assets/ui/char_create/attr_metal.png';
  static const String attrWood = 'assets/ui/char_create/attr_wood.png';
  static const String attrWater = 'assets/ui/char_create/attr_water.png';
  static const String attrFire = 'assets/ui/char_create/attr_fire.png';
  static const String attrEarth = 'assets/ui/char_create/attr_earth.png';
  static const String attrWind = 'assets/ui/char_create/attr_wind.png';
  static const String attrThunder = 'assets/ui/char_create/attr_thunder.png';
  static const String attrIllusion = 'assets/ui/char_create/attr_illusion.png';

  // ── L2 中央立繪 ───────────────────────────────
  static const String charMale = 'assets/ui/char_create/char_male.png';
  static const String charFemale = 'assets/ui/char_create/char_female.png';

  // ── L4 底中名稱 ───────────────────────────────
  static const String inputContact = 'assets/ui/char_create/input_contact.png';

  // ── 水墨按鈕 / 祥雲 label ─────────────────────
  /// 小筆刷底（legacy fallback）。
  static const String inkBtn01 = 'assets/ui/char_create/ink_btn01.png';

  /// 大筆刷底（legacy fallback）。
  static const String inkBtn02 = 'assets/ui/char_create/ink_btn02.png';

  /// 水墨底（靈根列、素質列、重置點數）。
  static const String inkBtn04 = 'assets/ui/char_create/ink_btn04.png';

  /// 水墨 label（legacy）。
  static const String inkLabel = 'assets/ui/char_create/ink_label.png';

  /// 祥雲 label（屬性分配、剩餘點數）。
  static const String cloudLabel01 = 'assets/ui/char_create/cloud_label01.png';

  /// 祥雲 label 鏡像（預載備用）。
  static const String cloudLabel02 = 'assets/ui/char_create/cloud_label02.png';

  /// 祥雲 label（預載，待指定用途）。
  static const String cloudLabel03 = 'assets/ui/char_create/cloud_label03.png';

  /// 祥雲 label（男/女、返回、進入遊戲，暫共用）。
  static const String cloudLabel04 = 'assets/ui/char_create/cloud_label04.png';

  /// 祥雲 label（預載，待指定用途）。
  static const String cloudLabel05 = 'assets/ui/char_create/cloud_label05.png';

  // ── 素質列 / 裝飾（legacy）──────────────────────
  static const String option = 'assets/ui/char_create/option.png';

  // ── L6 左上返回 ───────────────────────────────
  static const String backIcon = 'assets/ui/char_create/back_icon.png';
  static const String backIconHover =
      'assets/ui/char_create/back_icon_hover.png';
  static const String backIconPressed =
      'assets/ui/char_create/back_icon_pressed.png';

  // ── L3 右欄配點 ───────────────────────────────
  static const String spiritIcon = 'assets/ui/char_create/spirit_icon.png';
  static const String constitutionIcon =
      'assets/ui/char_create/constitution_icon.png';
  static const String agilityIcon = 'assets/ui/char_create/agility_icon.png';
  static const String intelIcon = 'assets/ui/char_create/intel_icon.png';
  static const String reduceBtn = 'assets/ui/char_create/reduce_btn.png';
  static const String addBtn = 'assets/ui/char_create/add_btn.png';

  static final List<String> allPreloadPaths = {
    GameUiAssets.dialogMessageBg,
    bg,
    attrMetal,
    attrWood,
    attrWater,
    attrFire,
    attrEarth,
    attrWind,
    attrThunder,
    attrIllusion,
    charMale,
    charFemale,
    inputContact,
    inkBtn01,
    inkBtn02,
    inkBtn04,
    inkLabel,
    cloudLabel01,
    cloudLabel02,
    cloudLabel03,
    cloudLabel04,
    cloudLabel05,
    spiritIcon,
    constitutionIcon,
    agilityIcon,
    intelIcon,
  }.toList();

  static const Set<String> decodeOnPreload = {
    bg,
    charMale,
    charFemale,
  };
}
