import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'載入中...'**
  String get loading;

  /// No description provided for @enteringCharacterUI.
  ///
  /// In zh, this message translates to:
  /// **'進入角色介面…'**
  String get enteringCharacterUI;

  /// No description provided for @enteringWorld.
  ///
  /// In zh, this message translates to:
  /// **'進入世界…'**
  String get enteringWorld;

  /// No description provided for @closingGame.
  ///
  /// In zh, this message translates to:
  /// **'正在關閉遊戲…'**
  String get closingGame;

  /// No description provided for @gameSizeWarning.
  ///
  /// In zh, this message translates to:
  /// **'警告：無法取得有效 game size，使用預設 1280×720'**
  String get gameSizeWarning;

  /// No description provided for @loginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登入失敗'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In zh, this message translates to:
  /// **'帳號或密碼錯誤'**
  String get invalidCredentials;

  /// No description provided for @charServiceUninitialized.
  ///
  /// In zh, this message translates to:
  /// **'角色服務尚未初始化'**
  String get charServiceUninitialized;

  /// No description provided for @commServiceUninitialized.
  ///
  /// In zh, this message translates to:
  /// **'通訊服務尚未初始化'**
  String get commServiceUninitialized;

  /// No description provided for @queryCharListFailed.
  ///
  /// In zh, this message translates to:
  /// **'查詢角色列表失敗'**
  String get queryCharListFailed;

  /// No description provided for @cannotLoginPrefix.
  ///
  /// In zh, this message translates to:
  /// **'目前'**
  String get cannotLoginPrefix;

  /// No description provided for @cannotLoginSuffix.
  ///
  /// In zh, this message translates to:
  /// **'，無法登入'**
  String get cannotLoginSuffix;

  /// No description provided for @charInfo.
  ///
  /// In zh, this message translates to:
  /// **'角色資訊'**
  String get charInfo;

  /// No description provided for @hpLabel.
  ///
  /// In zh, this message translates to:
  /// **'生命'**
  String get hpLabel;

  /// No description provided for @mpLabel.
  ///
  /// In zh, this message translates to:
  /// **'法力'**
  String get mpLabel;

  /// No description provided for @factionLabel.
  ///
  /// In zh, this message translates to:
  /// **'勢力'**
  String get factionLabel;

  /// No description provided for @natalWeaponLabel.
  ///
  /// In zh, this message translates to:
  /// **'仙藝'**
  String get natalWeaponLabel;

  /// No description provided for @coreTechniqueLabel.
  ///
  /// In zh, this message translates to:
  /// **'核心功法'**
  String get coreTechniqueLabel;

  /// No description provided for @lifeJobLabel.
  ///
  /// In zh, this message translates to:
  /// **'生活職業'**
  String get lifeJobLabel;

  /// No description provided for @defaultFaction.
  ///
  /// In zh, this message translates to:
  /// **'散修'**
  String get defaultFaction;

  /// No description provided for @defaultValueNone.
  ///
  /// In zh, this message translates to:
  /// **'無'**
  String get defaultValueNone;

  /// No description provided for @elementMetal.
  ///
  /// In zh, this message translates to:
  /// **'金'**
  String get elementMetal;

  /// No description provided for @elementWood.
  ///
  /// In zh, this message translates to:
  /// **'木'**
  String get elementWood;

  /// No description provided for @elementWater.
  ///
  /// In zh, this message translates to:
  /// **'水'**
  String get elementWater;

  /// No description provided for @elementFire.
  ///
  /// In zh, this message translates to:
  /// **'火'**
  String get elementFire;

  /// No description provided for @elementEarth.
  ///
  /// In zh, this message translates to:
  /// **'土'**
  String get elementEarth;

  /// No description provided for @elementWind.
  ///
  /// In zh, this message translates to:
  /// **'風'**
  String get elementWind;

  /// No description provided for @elementLightning.
  ///
  /// In zh, this message translates to:
  /// **'雷'**
  String get elementLightning;

  /// No description provided for @elementIllusion.
  ///
  /// In zh, this message translates to:
  /// **'幻'**
  String get elementIllusion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
