import 'package:flutter/material.dart';

import '../ui_xaml_assets.dart';
import '../ui_xaml_loader.dart';
import '../ui_xaml_parts.dart';
import '../ui_xaml_registry.dart';
import '../ui_xaml_spec_holder.dart';

/// 帳號登入畫面的顯示規格（設計稿像素，1920×1080）。
@immutable
class AccountUiSpec {
  const AccountUiSpec({
    this.backgroundAsset = 'assets/images/loading.png',
    this.fallbackBackgroundAsset = 'assets/images/launch_bg.png',
    this.backgroundColor = const Color(0xFF140E0C),
    this.loginArea = const XamlInkFade(
      box: XamlBox(centerX: 960, centerY: 470, width: 620, height: 620),
      color: Color(0xFF0E0F12),
      centerOpacity: 0,
      fadeX: 120,
      fadeY: 100,
    ),
    this.title = const XamlText(
      text: '',
      centerX: 960,
      centerY: 230,
      size: 34,
      color: Color(0xFFF2EADA),
    ),
    this.account = const XamlField(
      box: XamlBox(centerX: 960, centerY: 360, width: 390, height: 54),
      hint: '帳號',
      textSize: 18,
      textColor: Color(0xFFF2EADA),
      hintColor: Color(0xFFA8A093),
      lineColor: Color(0xFF3E7D80),
      focusLineColor: Color(0xFF74D2D5),
      lineWidth: 2,
    ),
    this.password = const XamlField(
      box: XamlBox(centerX: 960, centerY: 440, width: 390, height: 54),
      hint: '密碼',
      textSize: 18,
      textColor: Color(0xFFF2EADA),
      hintColor: Color(0xFFA8A093),
      lineColor: Color(0xFF3E7D80),
      focusLineColor: Color(0xFF74D2D5),
      lineWidth: 2,
    ),
    this.submit = const XamlButton(
      box: XamlBox(centerX: 960, centerY: 540, width: 390, height: 56),
      text: '登入',
      textSize: 24,
      textColor: Color(0xFFE8C86A),
    ),
    this.serverSelect = const XamlButton(
      box: XamlBox(centerX: 960, centerY: 620, width: 390, height: 44),
      text: '選擇伺服器',
      textSize: 16,
      textColor: Color(0xFFF2EADA),
    ),
    this.session = const XamlButton(
      box: XamlBox(centerX: 960, centerY: 680, width: 390, height: 40),
      text: '',
      textSize: 14,
      textColor: Color(0xFFA8A093),
    ),
  });

  final String backgroundAsset;
  final String fallbackBackgroundAsset;
  final Color backgroundColor;

  final XamlInkFade loginArea;
  final XamlText title;

  /// 帳號與密碼。兩者的 `box.width` 必然相同 —— XAML 裡都寫 `{fieldWidth}`。
  final XamlField account;
  final XamlField password;

  final XamlButton submit;
  final XamlButton serverSelect;

  /// 登出／離開遊戲；文字由 Dart 依登入狀態決定，所以 XAML 不寫 text。
  final XamlButton session;

  static const AccountUiSpec defaults = AccountUiSpec();

  static final holder = UiXamlSpecHolder<AccountUiSpec>(
    view: UiXamlRegistry.account,
    initial: defaults,
    build: _build,
  );

  static AccountUiSpec get current => holder.value;

  static AccountUiSpec _build(UiXamlResult result, UiXamlAssets assets) {
    final document = result.document;
    if (document == null) return defaults;
    const d = defaults;
    final bg = document.root.child('Background');

    String resolve(String? id, String fallback) =>
        id == null ? fallback : (assets.path(id, fallbackPath: fallback) ?? fallback);

    return AccountUiSpec(
      backgroundAsset: resolve(bg?.raw('asset'), d.backgroundAsset),
      fallbackBackgroundAsset:
          resolve(bg?.raw('fallbackAsset'), d.fallbackBackgroundAsset),
      backgroundColor: bg?.color('color', d.backgroundColor) ?? d.backgroundColor,
      loginArea: XamlInkFade.from(document.findById('loginArea'), d.loginArea),
      title: XamlText.from(document.findById('title'), d.title),
      account: XamlField.from(document.findById('account'), d.account),
      password: XamlField.from(document.findById('password'), d.password),
      submit: XamlButton.from(document.findById('submit'), d.submit),
      serverSelect:
          XamlButton.from(document.findById('serverSelect'), d.serverSelect),
      session: XamlButton.from(document.findById('session'), d.session),
    );
  }

  @visibleForTesting
  static AccountUiSpec fromResultForTest(
          UiXamlResult result, UiXamlAssets assets) =>
      _build(result, assets);
}
