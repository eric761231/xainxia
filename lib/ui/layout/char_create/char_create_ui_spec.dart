import 'package:flutter/material.dart';

import '../ui_scale.dart';
import 'char_create_ui_config.dart';
import 'char_create_ui_dev_watcher.dart';
import 'char_create_ui_loader.dart';

/// 創角 UI 切圖顯示規格（邏輯像素）。
///
/// 數值來自 [assets/ui/layouts/char_create_layout.xml]；
/// 固定 px 會依 [updateScaleFrom] 等比縮放；比例類（*Fraction）不縮放。
/// 請先呼叫 [ensureLoaded]，再 build 創角畫面。
abstract final class CharCreateUiSpec {
  static CharCreateUiConfig _config = CharCreateUiConfig();
  static bool _loaded = false;

  static final ValueNotifier<int> revision = ValueNotifier(0);

  static bool get isLoaded => _loaded;

  static double get scale => UiScale.value;

  static Future<void> ensureLoaded() async {
    await reload();
    CharCreateUiDevWatcher.ensureStarted();
  }

  static Future<void> reload() async {
    _config = await CharCreateUiLoader.load();
    _loaded = true;
    revision.value++;
  }

  /// 在 SafeArea 內可用區域更新等比縮放係數。
  static void updateScaleFrom(Size availableSize) {
    UiScale.updateFrom(
      availableSize,
      designWidth: _config.designWidth,
      designHeight: _config.designHeight,
      scaleMin: _config.scaleMin,
      scaleMax: _config.scaleMax,
    );
  }

  static double s(double designPx) => UiScale.s(designPx);

  static CharCreateUiConfig get _c => _config;

  static double _px(double v) => s(v);

  static double get screenPaddingH => _px(_c.screenPaddingH);
  static double get screenPaddingV => _px(_c.screenPaddingV);
  static double get columnGap => _px(_c.columnGap);
  static int get screenLeftFlex => _c.screenLeftFlex;
  static int get screenCenterFlex => _c.screenCenterFlex;
  static int get screenRightFlex => _c.screenRightFlex;
  static double get leftPanelWidth => _px(_c.leftPanelWidth);
  static double get leftPanelWidthMin => _px(_c.leftPanelWidthMin);
  static double get leftPanelWidthMax => _px(_c.leftPanelWidthMax);
  static double get leftPanelWidthResolved =>
      leftPanelWidth.clamp(leftPanelWidthMin, leftPanelWidthMax);
  static double get leftPanelHeightFraction => _c.leftPanelHeightFraction;
  static double get leftPanelTopOffset => _px(_c.leftPanelTopOffset);
  static double get rightPanelWidthFraction => _c.rightPanelWidthFraction;
  static double get rightPanelMinWidth => _px(_c.rightPanelMinWidth);
  static double get rightPanelMaxWidth => _px(_c.rightPanelMaxWidth);
  static double get rightPanelHeightFraction => _c.rightPanelHeightFraction;
  static double get rightPanelTopOffset => _px(_c.rightPanelTopOffset);

  static double resolveRightPanelWidth(double availableWidth) {
    return (availableWidth * _c.rightPanelWidthFraction).clamp(
      _px(_c.rightPanelMinWidth),
      _px(_c.rightPanelMaxWidth),
    );
  }

  static double get spiritRootTitleFontSize => _px(_c.spiritRootTitleFontSize);
  static double get spiritRootTitleGap => _px(_c.spiritRootTitleGap);
  static double get spiritRootTitleBarHeight => _px(_c.spiritRootTitleBarHeight);
  static double get spiritRootTitleBarWidthFraction =>
      _c.spiritRootTitleBarWidthFraction;
  static BoxFit get spiritRootTitleImageFit =>
      parseImageFit(_c.spiritRootTitleImageFit, BoxFit.fill);
  static double get spiritRootTitleImageOffsetH =>
      _px(_c.spiritRootTitleImageOffsetH);
  static double get spiritRootTitleImageOffsetV =>
      _px(_c.spiritRootTitleImageOffsetV);
  static BoxFit get spiritRootItemImageFit =>
      parseImageFit(_c.spiritRootItemImageFit, BoxFit.fitWidth);
  static double get spiritRootItemImageOffsetH =>
      _px(_c.spiritRootItemImageOffsetH);
  static double get spiritRootItemImageOffsetV =>
      _px(_c.spiritRootItemImageOffsetV);
  static double get spiritRootPanelPaddingTop => _px(_c.spiritRootPanelPaddingTop);
  static double get spiritRootPanelPaddingH => _px(_c.spiritRootPanelPaddingH);
  static double get spiritRootIconSize => _px(_c.spiritRootIconSize);
  static double get spiritRootItemMinHeight => _px(_c.spiritRootItemMinHeight);
  static double get spiritRootItemMaxHeight => _px(_c.spiritRootItemMaxHeight);
  static double get spiritRootItemRadius => _px(_c.spiritRootItemRadius);
  static double get spiritRootItemVMargin => _px(_c.spiritRootItemVMargin);
  static double get spiritRootItemSpacing => _px(_c.spiritRootItemSpacing);
  static double get spiritRootItemPadding => _px(_c.spiritRootItemPadding);
  static double get spiritRootItemPaddingH => _px(_c.spiritRootItemPaddingH);
  static double get spiritRootItemPaddingV => _px(_c.spiritRootItemPaddingV);
  static double get spiritRootUnselectedBgOpacity => _c.spiritRootUnselectedBgOpacity;
  static double get spiritRootSelectedBgOpacity => _c.spiritRootSelectedBgOpacity;
  static double get spiritRootUnselectedBorderOpacity => _c.spiritRootUnselectedBorderOpacity;
  static double get spiritRootUnselectedBorderWidth => _px(_c.spiritRootUnselectedBorderWidth);
  static double get spiritRootUnselectedHighlightOpacity => _c.spiritRootUnselectedHighlightOpacity;
  static double get spiritRootSelectedBorderOpacity => _c.spiritRootSelectedBorderOpacity;
  static double get spiritRootSelectedGlowOpacity => _c.spiritRootSelectedGlowOpacity;
  static double get spiritRootSelectedGlowBlur => _px(_c.spiritRootSelectedGlowBlur);
  static double get spiritRootSelectedGlowSpread => _px(_c.spiritRootSelectedGlowSpread);
  static double get spiritRootSelectedBorderWidth => _px(_c.spiritRootSelectedBorderWidth);
  static double get spiritRootNameFontSize => _px(_c.spiritRootNameFontSize);
  static double get spiritRootDescFontSize => _px(_c.spiritRootDescFontSize);
  static double get spiritRootCloudLabelHeight =>
      _px(_c.spiritRootCloudLabelHeight);
  static int get spiritRootUnselectedNameColor => _c.spiritRootUnselectedNameColor;
  static int get spiritRootUnselectedDescColor => _c.spiritRootUnselectedDescColor;

  static double get portraitStackWidthFactor => _c.portraitStackWidthFactor;
  static double get portraitStackHeightFactor => _c.portraitStackHeightFactor;
  static double get charPortraitBottomOffset => _px(_c.charPortraitBottomOffset);
  static double get charPortraitWidthFraction => _c.charPortraitWidthFraction;
  static double get charPortraitWidthMinFraction =>
      _c.charPortraitWidthMinFraction;
  static double get charPortraitWidthMaxFraction =>
      _c.charPortraitWidthMaxFraction;

  /// [imageWidthFraction] 經 XML widthMin/MaxFraction clamp 後的有效比例。
  static double get charPortraitImageWidthFractionResolved {
    final f = _c.charPortraitWidthFraction;
    final min = _c.charPortraitWidthMinFraction;
    final max = _c.charPortraitWidthMaxFraction;
    if (max > min) {
      return f.clamp(min, max);
    }
    return f;
  }

  static double get nameBarWidth => _px(_c.nameBarWidth);
  static double get nameBarMinWidth => _px(_c.nameBarMinWidth);
  static double get nameBarHeight => _px(_c.nameBarHeight);
  static double get nameBarBottom => _px(_c.nameBarBottom);
  static double get nameBarPaddingH => _px(_c.nameBarPaddingH);
  static double get nameBarPaddingV => _px(_c.nameBarPaddingV);
  static double get nameBarOffsetH => _px(_c.nameBarOffsetH);
  static double get nameBarImageOffsetH => _px(_c.nameBarImageOffsetH);
  static double get nameBarImageOffsetV => _px(_c.nameBarImageOffsetV);
  static double get nameFieldFontSize => _px(_c.nameFieldFontSize);
  static double get nameHintFontSize => _px(_c.nameHintFontSize);
  static double get nameHintOpacity => _c.nameHintOpacity;
  static double get nameFieldTextOffsetH => _px(_c.nameFieldTextOffsetH);
  static double get nameFieldTextOffsetV => _px(_c.nameFieldTextOffsetV);

  static double get genderSectionPaddingH => _px(_c.genderSectionPaddingH);
  static double get genderSectionPaddingV => _px(_c.genderSectionPaddingV);
  static double get genderSectionRadius => _px(_c.genderSectionRadius);
  static double get genderSectionBgOpacity => _c.genderSectionBgOpacity;
  static double get genderIconSize => _px(_c.genderIconSize);
  static double get genderTitleFontSize => _px(_c.genderTitleFontSize);
  static double get genderBtnWidth => _px(_c.genderBtnWidth);
  static double get genderBtnHeight => _px(_c.genderBtnHeight);
  static double get genderBtnRadius => _px(_c.genderBtnRadius);
  static double get genderBtnFontSize => _px(_c.genderBtnFontSize);
  static BoxFit get genderBtnImageFit =>
      parseImageFit(_c.genderBtnImageFit, BoxFit.fill);
  static double get genderBtnImageOffsetH => _px(_c.genderBtnImageOffsetH);
  static double get genderBtnImageOffsetV => _px(_c.genderBtnImageOffsetV);
  static double get genderUnselectedOverlayOpacity => _c.genderUnselectedOverlayOpacity;
  static double get genderUnselectedTextOpacity => _c.genderUnselectedTextOpacity;
  static double get genderSelectedBorderWidth => _px(_c.genderSelectedBorderWidth);
  static double get genderBtnGap => _px(_c.genderBtnGap);

  static double get statsSectionPadding => _px(_c.statsSectionPadding);
  static double get statsSectionPaddingTop => _px(_c.statsSectionPaddingTop);
  static double get statsTitleGap => _px(_c.statsTitleGap);
  static double get statsHeaderRowGap => _px(_c.statsHeaderRowGap);
  static double get statsPointsRowGap => _px(_c.statsPointsRowGap);
  static double get statsGenderGap => _px(_c.statsGenderGap);
  static double get statsResetGap => _px(_c.statsResetGap);
  static double get statsTitleBarHeight => _px(_c.statsTitleBarHeight);
  static double get statsTitleBarWidthFraction => _c.statsTitleBarWidthFraction;
  static BoxFit get statsTitleImageFit =>
      parseImageFit(_c.statsTitleImageFit, BoxFit.fill);
  static double get statsTitleImageOffsetH => _px(_c.statsTitleImageOffsetH);
  static double get statsTitleImageOffsetV => _px(_c.statsTitleImageOffsetV);
  static BoxFit get statRowImageFit =>
      parseImageFit(_c.statRowImageFit, BoxFit.fill);
  static double get statRowImageOffsetH => _px(_c.statRowImageOffsetH);
  static double get statRowImageOffsetV => _px(_c.statRowImageOffsetV);
  static double get resetBtnWidth => _px(_c.resetBtnWidth);
  static double get resetBtnHeight => _px(_c.resetBtnHeight);
  static BoxFit get resetBtnImageFit =>
      parseImageFit(_c.resetBtnImageFit, BoxFit.fill);
  static double get resetBtnImageOffsetH => _px(_c.resetBtnImageOffsetH);
  static double get resetBtnImageOffsetV => _px(_c.resetBtnImageOffsetV);
  static double get statsTitleLineWidth => _px(_c.statsTitleLineWidth);
  static double get statsTitleLineHeight => _px(_c.statsTitleLineHeight);
  static double get statsTitleLineGap => _px(_c.statsTitleLineGap);
  static double get statsPointsBarHeight => _px(_c.statsPointsBarHeight);
  static double get statsPointsBarWidthFraction =>
      _c.statsPointsBarWidthFraction;
  static double get statsPointsLabelWidth => _px(_c.statsPointsLabelWidth);
  static double get statsPointsLabelHeight => _px(_c.statsPointsLabelHeight);
  static double get statsPointsValueGap => _px(_c.statsPointsValueGap);
  static double get statsResetPointsRowGap => _px(_c.statsResetPointsRowGap);
  static double get statsSectionRadius => _px(_c.statsSectionRadius);
  static double get statsSectionBgOpacity => _c.statsSectionBgOpacity;
  static double get statsTitleFontSize => _px(_c.statsTitleFontSize);
  static double get statsPointsFontSize => _px(_c.statsPointsFontSize);
  static double get statRowHeight => _px(_c.statRowHeight);
  static double get statRowVMargin => _px(_c.statRowVMargin);
  static double get statRowPaddingH => _px(_c.statRowPaddingH);
  static double get statRowWidthFraction => _c.statRowWidthFraction;
  static double get statContentPaddingLeft => _px(_c.statContentPaddingLeft);
  static double get statAdjustBtnGap => _px(_c.statAdjustBtnGap);
  static double get statAdjustBtnPaddingRight => _px(_c.statAdjustBtnPaddingRight);
  static double get statIconLabelGap => _px(_c.statIconLabelGap);
  static double get statLabelOffsetH => _px(_c.statLabelOffsetH);
  static double get statIconOffsetH => _px(_c.statIconOffsetH);
  static double get statIconOffsetV => _px(_c.statIconOffsetV);
  static double get statIconSize => _px(_c.statIconSize);
  static double get statLabelFontSize => _px(_c.statLabelFontSize);
  static double get statLabelWidth => _px(_c.statLabelWidth);
  static double get statValueLabelGap => _px(_c.statValueLabelGap);
  static double get statValueWidth => _px(_c.statValueWidth);
  static double get statValueFontSize => _px(_c.statValueFontSize);
  static double get statAdjustBtnSize => _px(_c.statAdjustBtnSize);
  static double get statAdjustSymbolFontSize =>
      _px(_c.statAdjustSymbolFontSize);
  static double get statAdjustBtnDisabledOpacity => _c.statAdjustBtnDisabledOpacity;
  static double get statBarHeight => _px(_c.statBarHeight);
  static double get statBarPaddingH => _px(_c.statBarPaddingH);
  static double get resetBtnFontSize => _px(_c.resetBtnFontSize);

  static double get startBtnWidth => _px(_c.startBtnWidth);
  static double get startBtnMaxWidth => _px(_c.startBtnMaxWidth);
  static double get startBtnHeight => _px(_c.startBtnHeight);
  static double get startBtnMaxHeight => _px(_c.startBtnMaxHeight);
  static double get startBtnBottom => _px(_c.startBtnBottom);
  static double get startBtnRight => _px(_c.startBtnRight);
  static double get startBtnFontSize => _px(_c.startBtnFontSize);
  static double get startBtnDisabledOpacity => _c.startBtnDisabledOpacity;
  static BoxFit get startBtnImageFit =>
      parseImageFit(_c.startBtnImageFit, BoxFit.contain);
  static double get startBtnImageOffsetH => _px(_c.startBtnImageOffsetH);
  static double get startBtnImageOffsetV => _px(_c.startBtnImageOffsetV);
  static Color get startBtnHoverOverlay => _c.startBtnHoverOverlay;
  static Color get startBtnPressedOverlay => _c.startBtnPressedOverlay;

  static double get backBtnTop => _px(_c.backBtnTop);
  static double get backBtnLeft => _px(_c.backBtnLeft);
  static double get backBtnWidth => _px(_c.backBtnWidth);
  static double get backBtnHeight => _px(_c.backBtnHeight);
  static double get backIconSize => _px(_c.backIconSize);
  static double get backLabelGap => _px(_c.backLabelGap);
  static double get backLabelFontSize => _px(_c.backLabelFontSize);
  static double get backDisabledOpacity => _c.backDisabledOpacity;
  static double get backSafeExtra => _px(_c.backSafeExtra);
  static BoxFit get backBtnImageFit =>
      parseImageFit(_c.backBtnImageFit, BoxFit.fill);
  static double get backBtnImageOffsetH => _px(_c.backBtnImageOffsetH);
  static double get backBtnImageOffsetV => _px(_c.backBtnImageOffsetV);
  static Color get backBtnHoverOverlay => _c.backBtnHoverOverlay;
  static Color get backBtnPressedOverlay => _c.backBtnPressedOverlay;

  static Color get interactiveHoverOverlay => _c.interactiveHoverOverlay;
  static Color get interactivePressedOverlay => _c.interactivePressedOverlay;

  static int get colorTitle => _c.colorTitle;
  static int get colorAccent => _c.colorAccent;
  static int get colorGenderTitle => _c.colorGenderTitle;
  static int get colorStatLabel => _c.colorStatLabel;

  static Color get btnShadowNormalColor => _c.btnShadowNormalColor;
  static double get btnShadowNormalBlur => _px(_c.btnShadowNormalBlur);
  static Color get btnShadowHoverColor => _c.btnShadowHoverColor;
  static double get btnShadowHoverBlur => _px(_c.btnShadowHoverBlur);
  static Color get btnShadowPressedColor => _c.btnShadowPressedColor;
  static double get btnShadowPressedBlur => _px(_c.btnShadowPressedBlur);
  static Color get btnShadowSelectedColor => _c.btnShadowSelectedColor;
  static double get btnShadowSelectedBlur => _px(_c.btnShadowSelectedBlur);

  static Color get cloudTextNormalColor => _c.cloudTextNormalColor;
  static Color get cloudTextHoverColor => _c.cloudTextHoverColor;
  static Color get cloudTextPressedColor => _c.cloudTextPressedColor;
  static Color get cloudTextSelectedColor => _c.cloudTextSelectedColor;

  /// 將 XML imageFit 字串轉為 [BoxFit]（不區分大小寫）。
  static BoxFit parseImageFit(String raw, BoxFit fallback) {
    switch (raw.toLowerCase()) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaledown':
        return BoxFit.scaleDown;
      default:
        return fallback;
    }
  }
}
