import 'package:flutter/material.dart';

import 'char_select_ui_config.dart';
import 'char_select_ui_loader.dart';
import 'char_select_ui_scale.dart';

/// 角色選擇 UI 切圖顯示規格（邏輯像素）。
///
/// 固定 px 依 [updateScaleFrom] 等比縮放；比例類（*Fraction）不縮放。
/// 請先呼叫 [ensureLoaded]，再 build 角色選擇畫面。
abstract final class CharSelectUiSpec {
  static CharSelectUiConfig _config = CharSelectUiConfig();
  static bool _loaded = false;

  static final ValueNotifier<int> revision = ValueNotifier(0);

  static bool get isLoaded => _loaded;

  static double get scale => CharSelectUiScale.value;

  static Future<void> ensureLoaded() async {
    await reload();
  }

  static Future<void> reload() async {
    _config = await CharSelectUiLoader.load();
    _loaded = true;
    revision.value++;
  }

  static void updateScaleFrom(Size availableSize) {
    CharSelectUiScale.updateFrom(availableSize, _config);
  }

  static double s(double designPx) => CharSelectUiScale.s(designPx);

  static CharSelectUiConfig get _c => _config;
  static double _px(double v) => s(v);

  // topBar
  static double get topBarHeight => _px(_c.topBarHeight);
  static double get topBarPaddingH => _px(_c.topBarPaddingH);
  static double get topBarPaddingV => _px(_c.topBarPaddingV);
  static double get topBarTitleFontSize => _px(_c.topBarTitleFontSize);
  static double get topBarBackBtnWidth => _px(_c.topBarBackBtnWidth);
  static double get topBarBackBtnHeight => _px(_c.topBarBackBtnHeight);
  static double get topBarBackIconSize => _px(_c.topBarBackIconSize);
  static double get topBarBackLabelFontSize => _px(_c.topBarBackLabelFontSize);
  static double get topBarSlotFontSize => _px(_c.topBarSlotFontSize);

  // leftPanel
  static double get leftPanelWidth => _px(_c.leftPanelWidth);
  static double get leftPanelWidthMin => _px(_c.leftPanelWidthMin);
  static double get leftPanelWidthMax => _px(_c.leftPanelWidthMax);
  static double get leftPanelWidthResolved =>
      leftPanelWidth.clamp(leftPanelWidthMin, leftPanelWidthMax);
  static double get leftPanelTopOffset => _px(_c.leftPanelTopOffset);
  static double get leftPanelPaddingH => _px(_c.leftPanelPaddingH);
  static double get leftPanelListSpacing => _px(_c.leftPanelListSpacing);

  // centerPanel
  static double get centerPortraitWidthFraction => _c.centerPortraitWidthFraction;
  static double get centerPortraitBottomOffset => _px(_c.centerPortraitBottomOffset);
  static double get centerNameFontSize => _px(_c.centerNameFontSize);
  static double get centerLevelFontSize => _px(_c.centerLevelFontSize);
  static double get centerNamePaddingH => _px(_c.centerNamePaddingH);

  // rightPanel
  static double get rightPanelWidthFraction => _c.rightPanelWidthFraction;
  static double get rightPanelMinWidth => _px(_c.rightPanelMinWidth);
  static double get rightPanelMaxWidth => _px(_c.rightPanelMaxWidth);
  static double get rightPanelTopOffset => _px(_c.rightPanelTopOffset);
  static double get rightPanelPaddingH => _px(_c.rightPanelPaddingH);
  static double get rightPanelPaddingV => _px(_c.rightPanelPaddingV);
  static double get rightPanelSectionGap => _px(_c.rightPanelSectionGap);
  static double get rightPanelSectionRadius => _px(_c.rightPanelSectionRadius);
  static double get rightPanelSectionBgOpacity => _c.rightPanelSectionBgOpacity;

  static double resolveRightPanelWidth(double availableWidth) {
    return (availableWidth * _c.rightPanelWidthFraction).clamp(
      _px(_c.rightPanelMinWidth),
      _px(_c.rightPanelMaxWidth),
    );
  }

  // bottomBar
  static double get bottomBarHeight => _px(_c.bottomBarHeight);
  static double get bottomBarPaddingH => _px(_c.bottomBarPaddingH);
  static double get bottomBarPaddingV => _px(_c.bottomBarPaddingV);
  static double get bottomBarBtnHeight => _px(_c.bottomBarBtnHeight);
  static double get bottomBarBtnRadius => _px(_c.bottomBarBtnRadius);
  static double get bottomBarEnterBtnWidth => _px(_c.bottomBarEnterBtnWidth);
  static double get bottomBarSideBtnWidth => _px(_c.bottomBarSideBtnWidth);
  static double get bottomBarFontSize => _px(_c.bottomBarFontSize);

  // charCard
  static double get cardHeight => _px(_c.cardHeight);
  static double get cardRadius => _px(_c.cardRadius);
  static double get cardPaddingH => _px(_c.cardPaddingH);
  static double get cardPaddingV => _px(_c.cardPaddingV);
  static double get cardIconSize => _px(_c.cardIconSize);
  static double get cardIconRadius => _px(_c.cardIconRadius);
  static double get cardNameGap => _px(_c.cardNameGap);
  static double get cardNameFontSize => _px(_c.cardNameFontSize);
  static double get cardLevelFontSize => _px(_c.cardLevelFontSize);
  static double get cardAttrIconSize => _px(_c.cardAttrIconSize);
  static double get cardUnselectedBgOpacity => _c.cardUnselectedBgOpacity;
  static double get cardSelectedBgOpacity => _c.cardSelectedBgOpacity;
  static double get cardUnselectedBorderOpacity => _c.cardUnselectedBorderOpacity;
  static double get cardUnselectedBorderWidth => _c.cardUnselectedBorderWidth;
  static double get cardSelectedBorderOpacity => _c.cardSelectedBorderOpacity;
  static double get cardSelectedBorderWidth => _c.cardSelectedBorderWidth;
  static double get cardSelectedGlowOpacity => _c.cardSelectedGlowOpacity;
  static double get cardSelectedGlowBlur => _c.cardSelectedGlowBlur;

  // infoPanel
  static double get infoPanelTitleBarHeight => _px(_c.infoPanelTitleBarHeight);
  static double get infoPanelTitleFontSize => _px(_c.infoPanelTitleFontSize);
  static double get infoPanelTitleBarWidthFraction => _c.infoPanelTitleBarWidthFraction;
  static double get infoPanelPortraitSize => _px(_c.infoPanelPortraitSize);
  static double get infoPanelPortraitRadius => _px(_c.infoPanelPortraitRadius);
  static double get infoPanelNameFontSize => _px(_c.infoPanelNameFontSize);
  static double get infoPanelLevelBadgePaddingH => _px(_c.infoPanelLevelBadgePaddingH);
  static double get infoPanelLevelBadgePaddingV => _px(_c.infoPanelLevelBadgePaddingV);
  static double get infoPanelLevelBadgeRadius => _px(_c.infoPanelLevelBadgeRadius);
  static double get infoPanelLevelBadgeFontSize => _px(_c.infoPanelLevelBadgeFontSize);
  static double get infoPanelLabelFontSize => _px(_c.infoPanelLabelFontSize);
  static double get infoPanelValueFontSize => _px(_c.infoPanelValueFontSize);
  static double get infoPanelAttrIconSize => _px(_c.infoPanelAttrIconSize);
  static double get infoPanelRowHeight => _px(_c.infoPanelRowHeight);
  static double get infoPanelRowSpacing => _px(_c.infoPanelRowSpacing);

  // colors
  static int get colorAccent => _c.colorAccent;
  static int get colorTitle => _c.colorTitle;
  static int get colorLabel => _c.colorLabel;
  static int get colorDanger => _c.colorDanger;
  static int get colorCardName => _c.colorCardName;
  static int get colorCardLevel => _c.colorCardLevel;

  // overlays
  static Color get enterBtnHoverOverlay => _c.enterBtnHoverOverlay;
  static Color get enterBtnPressedOverlay => _c.enterBtnPressedOverlay;
  static Color get createBtnHoverOverlay => _c.createBtnHoverOverlay;
  static Color get createBtnPressedOverlay => _c.createBtnPressedOverlay;
  static Color get deleteBtnHoverOverlay => _c.deleteBtnHoverOverlay;
  static Color get deleteBtnPressedOverlay => _c.deleteBtnPressedOverlay;
  static Color get backBtnHoverOverlay => _c.backBtnHoverOverlay;
  static Color get backBtnPressedOverlay => _c.backBtnPressedOverlay;
  static Color get cardHoverOverlay => _c.cardHoverOverlay;
  static Color get cardPressedOverlay => _c.cardPressedOverlay;
}
