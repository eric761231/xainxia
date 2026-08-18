// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get loading => '載入中...';

  @override
  String get enteringCharacterUI => '進入角色介面…';

  @override
  String get enteringWorld => '進入世界…';

  @override
  String get closingGame => '正在關閉遊戲…';

  @override
  String get gameSizeWarning => '警告：無法取得有效 game size，使用預設 1280×720';

  @override
  String get loginFailed => '登入失敗';

  @override
  String get invalidCredentials => '帳號或密碼錯誤';

  @override
  String get charServiceUninitialized => '角色服務尚未初始化';

  @override
  String get commServiceUninitialized => '通訊服務尚未初始化';

  @override
  String get queryCharListFailed => '查詢角色列表失敗';

  @override
  String get cannotLoginPrefix => '目前';

  @override
  String get cannotLoginSuffix => '，無法登入';

  @override
  String get charInfo => '角色資訊';

  @override
  String get hpLabel => '生命';

  @override
  String get mpLabel => '法力';

  @override
  String get factionLabel => '勢力';

  @override
  String get natalWeaponLabel => '仙藝';

  @override
  String get coreTechniqueLabel => '核心功法';

  @override
  String get lifeJobLabel => '生活職業';

  @override
  String get defaultFaction => '散修';

  @override
  String get defaultValueNone => '無';

  @override
  String get elementMetal => '金';

  @override
  String get elementWood => '木';

  @override
  String get elementWater => '水';

  @override
  String get elementFire => '火';

  @override
  String get elementEarth => '土';

  @override
  String get elementWind => '風';

  @override
  String get elementLightning => '雷';

  @override
  String get elementIllusion => '幻';
}
