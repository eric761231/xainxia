import 'package:flutter/material.dart';

/// 創角 UI 執行期配置（預設值 + [CharCreateUiLoader] 從 XML 覆寫）。
class CharCreateUiConfig {
  CharCreateUiConfig();

  // 基準稿與縮放限制（對應 <charCreate designWidth designHeight scaleMin scaleMax>）
  double designWidth = 1920;
  double designHeight = 1080;
  double scaleMin = 0.65;
  double scaleMax = 1.35;

  // layout: portrait
  double portraitStackWidthFactor = 0.55;
  double portraitStackHeightFactor = 0.88;
  double charPortraitBottomOffset = 28;
  double charPortraitWidthFraction = 0.60;
  double charPortraitWidthMinFraction = 0.50;
  double charPortraitWidthMaxFraction = 2.0;

  // layout: screen
  double screenPaddingH = 16;
  double screenPaddingV = 8;
  double columnGap = 12;
  int screenLeftFlex = 3;
  int screenCenterFlex = 2;
  int screenRightFlex = 3;

  // layout: leftPanel
  double leftPanelWidth = 360;
  double leftPanelWidthMin = 300;
  double leftPanelWidthMax = 420;
  double leftPanelHeightFraction = 0.88;
  double leftPanelTopOffset = 92;

  // layout: rightPanel
  double rightPanelWidthFraction = 0.34;
  double rightPanelMinWidth = 300;
  double rightPanelMaxWidth = 480;
  double rightPanelHeightFraction = 0.72;
  double rightPanelTopOffset = 58;

  // layout: nameBar
  double nameBarWidth = 360;
  double nameBarMinWidth = 300;
  double nameBarHeight = 81;
  double nameBarBottom = 24;
  double nameBarPaddingH = 20;
  double nameBarPaddingV = 0;
  double nameBarOffsetH = 0;
  double nameBarImageOffsetH = 0;
  double nameBarImageOffsetV = 0;

  // layout: startBtn
  double startBtnWidth = 720;
  double startBtnMaxWidth = 750;
  double startBtnHeight = 96;
  double startBtnMaxHeight = 96;
  double startBtnBottom = 24;
  double startBtnRight = 24;
  double startBtnFontSize = 27;
  double startBtnDisabledOpacity = 0.50;
  String startBtnImageFit = 'contain';
  double startBtnImageOffsetH = 0;
  double startBtnImageOffsetV = 0;

  // layout: backBtn
  double backBtnTop = 16;
  double backBtnLeft = 16;
  double backBtnWidth = 240;
  double backBtnHeight = 72;
  double backIconSize = 28;
  double backLabelGap = 4;
  double backLabelFontSize = 27;
  double backDisabledOpacity = 0.40;
  double backSafeExtra = 4;
  String backBtnImageFit = 'fill';
  double backBtnImageOffsetH = 0;
  double backBtnImageOffsetV = 0;

  // spiritRoot
  double spiritRootPanelPaddingTop = 8;
  double spiritRootPanelPaddingH = 12;
  double spiritRootTitleFontSize = 27;
  double spiritRootTitleGap = 4;
  double spiritRootTitleBarHeight = 54;
  double spiritRootTitleBarWidthFraction = 1.0;
  String spiritRootTitleImageFit = 'fill';
  double spiritRootTitleImageOffsetH = 0;
  double spiritRootTitleImageOffsetV = 0;
  String spiritRootItemImageFit = 'fitWidth';
  double spiritRootItemImageOffsetH = 0;
  double spiritRootItemImageOffsetV = 0;
  double spiritRootIconSize = 36;
  double spiritRootItemMinHeight = 36;
  double spiritRootItemMaxHeight = 52;
  double spiritRootItemRadius = 8;
  double spiritRootItemVMargin = 0;
  double spiritRootItemSpacing = 4;
  double spiritRootItemPadding = 8;
  double spiritRootItemPaddingH = 8;
  double spiritRootItemPaddingV = 4;
  double spiritRootUnselectedBgOpacity = 0.20;
  double spiritRootSelectedBgOpacity = 0.18;
  double spiritRootUnselectedBorderOpacity = 0.24;
  double spiritRootUnselectedBorderWidth = 1;
  double spiritRootUnselectedHighlightOpacity = 0.06;
  double spiritRootSelectedBorderOpacity = 1.0;
  double spiritRootSelectedGlowOpacity = 0.35;
  double spiritRootSelectedGlowBlur = 8;
  double spiritRootSelectedGlowSpread = 0;
  double spiritRootSelectedBorderWidth = 1.5;
  double spiritRootNameFontSize = 20;
  double spiritRootDescFontSize = 15;
  double spiritRootCloudLabelHeight = 58;
  int spiritRootUnselectedNameColor = 0xFF999999;
  int spiritRootUnselectedDescColor = 0xFF666666;

  // nameField
  double nameFieldFontSize = 21;
  double nameHintFontSize = 20;
  double nameHintOpacity = 0.54;
  double nameFieldTextOffsetH = 0;
  double nameFieldTextOffsetV = 0;

  // gender
  double genderSectionPaddingH = 8;
  double genderSectionPaddingV = 6;
  double genderSectionRadius = 12;
  double genderSectionBgOpacity = 0.30;
  double genderIconSize = 32;
  double genderTitleFontSize = 14;
  double genderBtnWidth = 203;
  double genderBtnHeight = 60;
  double genderBtnRadius = 6;
  double genderBtnFontSize = 19;
  String genderBtnImageFit = 'fill';
  double genderBtnImageOffsetH = 0;
  double genderBtnImageOffsetV = 0;
  double genderUnselectedOverlayOpacity = 0.45;
  double genderUnselectedTextOpacity = 0.70;
  double genderSelectedBorderWidth = 1.5;
  double genderBtnGap = 8;

  // stats
  double statsSectionPadding = 12;
  double statsSectionPaddingTop = 8;
  double statsTitleGap = 10;
  double statsHeaderRowGap = 6;
  double statsPointsRowGap = 10;
  double statsGenderGap = 14;
  double statsResetGap = 6;
  double statsTitleBarHeight = 54;
  double statsTitleBarWidthFraction = 0.92;
  String statsTitleImageFit = 'fill';
  double statsTitleImageOffsetH = 0;
  double statsTitleImageOffsetV = 0;
  String statRowImageFit = 'fill';
  double statRowImageOffsetH = 0;
  double statRowImageOffsetV = 0;
  double resetBtnWidth = 120;
  double resetBtnHeight = 48;
  String resetBtnImageFit = 'fill';
  double resetBtnImageOffsetH = 0;
  double resetBtnImageOffsetV = 0;
  double statsTitleLineWidth = 48;
  double statsTitleLineHeight = 24;
  double statsTitleLineGap = 8;
  double statsPointsBarHeight = 60;
  double statsPointsBarWidthFraction = 0.92;
  double statsPointsLabelWidth = 180;
  double statsPointsLabelHeight = 48;
  double statsPointsValueGap = 4;
  double statsResetPointsRowGap = 12;
  double statsSectionRadius = 12;
  double statsSectionBgOpacity = 0.35;
  double statsTitleFontSize = 21;
  double statsPointsFontSize = 18;
  double statRowHeight = 63;
  double statRowVMargin = 3;
  double statRowPaddingH = 8;
  double statRowWidthFraction = 0.92;
  double statContentPaddingLeft = 0;
  double statAdjustBtnGap = 12;
  double statAdjustBtnPaddingRight = 0;
  double statIconLabelGap = 9;
  double statLabelOffsetH = 0;
  double statIconOffsetH = 0;
  double statIconOffsetV = 0;
  double statIconSize = 36;
  double statLabelFontSize = 18;
  double statLabelWidth = 54;
  double statValueLabelGap = 6;
  double statValueWidth = 54;
  double statValueFontSize = 17;
  double statAdjustBtnSize = 30;
  double statAdjustSymbolFontSize = 30;
  double statAdjustBtnDisabledOpacity = 0.40;
  double statBarHeight = 10;
  double statBarPaddingH = 4;
  double resetBtnFontSize = 17;

  // colors
  int colorTitle = 0xFFE5D5C5;
  int colorAccent = 0xFFE8C547;
  int colorGenderTitle = 0xFFE4E4E4;
  int colorStatLabel = 0xFFEEEEEE;

  // overlays
  Color startBtnHoverOverlay = const Color(0x33FFFFFF);
  Color startBtnPressedOverlay = const Color(0x44000000);
  Color backBtnHoverOverlay = const Color(0x33E8C547);
  Color backBtnPressedOverlay = const Color(0x55000000);
  Color interactiveHoverOverlay = const Color(0x22FFFFFF);
  Color interactivePressedOverlay = const Color(0x44000000);

  // textShadows — 按鈕文字三態陰影（白字 + 灰階陰影）
  Color btnShadowNormalColor = const Color(0x88444444);
  double btnShadowNormalBlur = 4;
  Color btnShadowHoverColor = const Color(0x88AAAAAA);
  double btnShadowHoverBlur = 5;
  Color btnShadowPressedColor = const Color(0x88CCCCCC);
  double btnShadowPressedBlur = 4;
  Color btnShadowSelectedColor = const Color(0x88999999);
  double btnShadowSelectedBlur = 5;

  // cloudTextShadows — 祥雲底文字色（深黑 / 淺灰）
  Color cloudTextNormalColor = const Color(0xFF1A1A1A);
  Color cloudTextHoverColor = const Color(0xFFAAAAAA);
  Color cloudTextPressedColor = const Color(0xFFCCCCCC);
  Color cloudTextSelectedColor = const Color(0xFF888888);
}
