import 'package:flutter/material.dart';

/// 角色選擇 UI 執行期配置（預設值 + [CharSelectUiLoader] 從 XML 覆寫）。
class CharSelectUiConfig {
  CharSelectUiConfig();

  // 基準稿與縮放限制
  double designWidth = 1920;
  double designHeight = 1080;
  double scaleMin = 0.65;
  double scaleMax = 1.35;

  // layout: topBar
  double topBarHeight = 72;
  double topBarPaddingH = 16;
  double topBarPaddingV = 8;
  double topBarTitleFontSize = 36;
  double topBarBackBtnWidth = 200;
  double topBarBackBtnHeight = 60;
  double topBarBackIconSize = 28;
  double topBarBackLabelFontSize = 24;
  double topBarSlotFontSize = 20;

  // layout: leftPanel
  double leftPanelWidth = 320;
  double leftPanelWidthMin = 260;
  double leftPanelWidthMax = 380;
  double leftPanelTopOffset = 8;
  double leftPanelPaddingH = 12;
  double leftPanelListSpacing = 8;

  // layout: centerPanel
  double centerPortraitWidthFraction = 0.85;
  double centerPortraitBottomOffset = 80;
  double centerNameFontSize = 38;
  double centerLevelFontSize = 22;
  double centerNamePaddingH = 12;

  // layout: rightPanel
  double rightPanelWidthFraction = 0.30;
  double rightPanelMinWidth = 280;
  double rightPanelMaxWidth = 440;
  double rightPanelTopOffset = 8;
  double rightPanelPaddingH = 12;
  double rightPanelPaddingV = 10;
  double rightPanelSectionGap = 10;
  double rightPanelSectionRadius = 10;
  double rightPanelSectionBgOpacity = 0.35;

  // layout: bottomBar
  double bottomBarHeight = 80;
  double bottomBarPaddingH = 16;
  double bottomBarPaddingV = 8;
  double bottomBarBtnHeight = 60;
  double bottomBarBtnRadius = 8;
  double bottomBarEnterBtnWidth = 340;
  double bottomBarSideBtnWidth = 240;
  double bottomBarFontSize = 26;

  // styles: charCard
  double cardHeight = 88;
  double cardRadius = 10;
  double cardPaddingH = 12;
  double cardPaddingV = 10;
  double cardIconSize = 56;
  double cardIconRadius = 28;
  double cardNameGap = 10;
  double cardNameFontSize = 24;
  double cardLevelFontSize = 18;
  double cardAttrIconSize = 28;
  double cardUnselectedBgOpacity = 0.18;
  double cardSelectedBgOpacity = 0.25;
  double cardUnselectedBorderOpacity = 0.22;
  double cardUnselectedBorderWidth = 1.0;
  double cardSelectedBorderOpacity = 1.0;
  double cardSelectedBorderWidth = 1.5;
  double cardSelectedGlowOpacity = 0.35;
  double cardSelectedGlowBlur = 8;

  // styles: infoPanel
  double infoPanelTitleBarHeight = 52;
  double infoPanelTitleFontSize = 28;
  double infoPanelTitleBarWidthFraction = 0.90;
  double infoPanelPortraitSize = 72;
  double infoPanelPortraitRadius = 36;
  double infoPanelNameFontSize = 26;
  double infoPanelLevelBadgePaddingH = 10;
  double infoPanelLevelBadgePaddingV = 4;
  double infoPanelLevelBadgeRadius = 6;
  double infoPanelLevelBadgeFontSize = 18;
  double infoPanelLabelFontSize = 20;
  double infoPanelValueFontSize = 20;
  double infoPanelAttrIconSize = 32;
  double infoPanelRowHeight = 36;
  double infoPanelRowSpacing = 6;

  // colors
  int colorAccent = 0xFFE8C547;
  int colorTitle = 0xFFE5D5C5;
  int colorLabel = 0xFFCCBBAA;
  int colorDanger = 0xFFCC4444;
  int colorCardName = 0xFFEEEEEE;
  int colorCardLevel = 0xFFAAAAAA;

  // overlays
  Color enterBtnHoverOverlay = const Color(0x33FFFFFF);
  Color enterBtnPressedOverlay = const Color(0x44000000);
  Color createBtnHoverOverlay = const Color(0x22FFFFFF);
  Color createBtnPressedOverlay = const Color(0x44000000);
  Color deleteBtnHoverOverlay = const Color(0x33FF4444);
  Color deleteBtnPressedOverlay = const Color(0x55000000);
  Color backBtnHoverOverlay = const Color(0x33E8C547);
  Color backBtnPressedOverlay = const Color(0x55000000);
  Color cardHoverOverlay = const Color(0x22FFFFFF);
  Color cardPressedOverlay = const Color(0x44000000);
}
