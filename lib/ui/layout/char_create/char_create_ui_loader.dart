import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import '../xml_attr.dart';

import 'char_create_ui_config.dart';
import 'char_create_ui_source_stub.dart'
    if (dart.library.io) 'char_create_ui_source_io.dart';

/// 從 [CharCreateUiLoader.assetPath] 載入創角 UI 配置。
/// 對應 [assets/ui/layouts/char_create_layout.xml]；
/// PNG 路徑見 [CharCreateUiAssets]。
abstract final class CharCreateUiLoader {
  static const assetPath = 'assets/ui/layouts/char_create_layout.xml';

  static Future<CharCreateUiConfig> load() async {
    final config = CharCreateUiConfig();
    try {
      final raw = await readDebugAssetFile(assetPath) ??
          await rootBundle.loadString(assetPath);
      _applyXml(config, XmlDocument.parse(raw).rootElement);
    } catch (_) {
      // 缺檔或解析失敗時使用 CharCreateUiConfig 內建預設值。
    }
    return config;
  }

  static void _applyXml(CharCreateUiConfig c, XmlElement root) {
    _applyRoot(c, root);
    final layout = root.getElement('layout');
    if (layout != null) {
      _applyPortrait(c, layout.getElement('portrait'));
      _applyScreen(c, layout.getElement('screen'));
      _applyLeftPanel(c, layout.getElement('leftPanel'));
      _applyRightPanel(c, layout.getElement('rightPanel'));
      _applyNameBar(c, layout.getElement('nameBar'));
      _applyStartBtn(c, layout.getElement('startBtn'));
      _applyBackBtn(c, layout.getElement('backBtn'));
    }

    final styles = root.getElement('styles');
    if (styles != null) {
      _applySpiritRoot(c, styles.getElement('spiritRoot'));
      _applyNameField(c, styles.getElement('nameField'));
      _applyGender(c, styles.getElement('gender'));
      _applyStats(c, styles.getElement('stats'));
      _applyColors(c, styles.getElement('colors'));
      _applyOverlays(c, styles.getElement('overlays'));
      _applyTextShadows(c, styles.getElement('textShadows'));
      _applyCloudTextShadows(c, styles.getElement('cloudTextShadows'));
    }
  }

  static void _applyRoot(CharCreateUiConfig c, XmlElement root) {
    c.designWidth = XmlAttr.d(root, 'designWidth', c.designWidth);
    c.designHeight = XmlAttr.d(root, 'designHeight', c.designHeight);
    c.scaleMin = XmlAttr.d(root, 'scaleMin', c.scaleMin);
    c.scaleMax = XmlAttr.d(root, 'scaleMax', c.scaleMax);
  }

  static void _applyPortrait(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.portraitStackWidthFactor = XmlAttr.d(el, 'stackWidthFactor', c.portraitStackWidthFactor);
    c.portraitStackHeightFactor = XmlAttr.d(el, 'stackHeightFactor', c.portraitStackHeightFactor);
    c.charPortraitBottomOffset = XmlAttr.d(el, 'bottomOffset', c.charPortraitBottomOffset);
    c.charPortraitWidthFraction = XmlAttr.d(el, 'imageWidthFraction', c.charPortraitWidthFraction);
    c.charPortraitWidthMinFraction = XmlAttr.d(el, 'widthMinFraction', c.charPortraitWidthMinFraction);
    c.charPortraitWidthMaxFraction = XmlAttr.d(el, 'widthMaxFraction', c.charPortraitWidthMaxFraction);
  }

  static void _applyScreen(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.screenPaddingH = XmlAttr.d(el, 'paddingH', c.screenPaddingH);
    c.screenPaddingV = XmlAttr.d(el, 'paddingV', c.screenPaddingV);
    c.columnGap = XmlAttr.d(el, 'columnGap', c.columnGap);
    c.screenLeftFlex = XmlAttr.i(el, 'leftFlex', c.screenLeftFlex);
    c.screenCenterFlex = XmlAttr.i(el, 'centerFlex', c.screenCenterFlex);
    c.screenRightFlex = XmlAttr.i(el, 'rightFlex', c.screenRightFlex);
  }

  static void _applyLeftPanel(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.leftPanelWidth = XmlAttr.d(el, 'width', c.leftPanelWidth);
    c.leftPanelWidthMin = XmlAttr.d(el, 'widthMin', c.leftPanelWidthMin);
    c.leftPanelWidthMax = XmlAttr.d(el, 'widthMax', c.leftPanelWidthMax);
    c.leftPanelHeightFraction = XmlAttr.d(el, 'heightFraction', c.leftPanelHeightFraction);
    c.leftPanelTopOffset = XmlAttr.d(el, 'topOffset', c.leftPanelTopOffset);
  }

  static void _applyRightPanel(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.rightPanelWidthFraction = XmlAttr.d(el, 'widthFraction', c.rightPanelWidthFraction);
    c.rightPanelMinWidth = XmlAttr.d(el, 'minWidth', c.rightPanelMinWidth);
    c.rightPanelMaxWidth = XmlAttr.d(el, 'maxWidth', c.rightPanelMaxWidth);
    c.rightPanelHeightFraction = XmlAttr.d(el, 'heightFraction', c.rightPanelHeightFraction);
    c.rightPanelTopOffset = XmlAttr.d(el, 'topOffset', c.rightPanelTopOffset);
  }

  static void _applyNameBar(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.nameBarBottom = XmlAttr.d(el, 'bottom', c.nameBarBottom);
    c.nameBarWidth = XmlAttr.d(el, 'width', c.nameBarWidth);
    c.nameBarMinWidth = XmlAttr.d(el, 'minWidth', c.nameBarMinWidth);
    c.nameBarHeight = XmlAttr.d(el, 'height', c.nameBarHeight);
    c.nameBarPaddingH = XmlAttr.d(el, 'paddingH', c.nameBarPaddingH);
    c.nameBarPaddingV = XmlAttr.d(el, 'paddingV', c.nameBarPaddingV);
    c.nameBarOffsetH = XmlAttr.d(el, 'offsetH', c.nameBarOffsetH);
    c.nameBarImageOffsetH = XmlAttr.d(el, 'imageOffsetH', c.nameBarImageOffsetH);
    c.nameBarImageOffsetV = XmlAttr.d(el, 'imageOffsetV', c.nameBarImageOffsetV);
  }

  static void _applyStartBtn(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.startBtnBottom = XmlAttr.d(el, 'bottom', c.startBtnBottom);
    c.startBtnRight = XmlAttr.d(el, 'right', c.startBtnRight);
    c.startBtnWidth = XmlAttr.d(el, 'width', c.startBtnWidth);
    c.startBtnMaxWidth = XmlAttr.d(el, 'maxWidth', c.startBtnMaxWidth);
    c.startBtnHeight = XmlAttr.d(el, 'height', c.startBtnHeight);
    c.startBtnMaxHeight = XmlAttr.d(el, 'maxHeight', c.startBtnMaxHeight);
    c.startBtnFontSize = XmlAttr.d(el, 'fontSize', c.startBtnFontSize);
    c.startBtnDisabledOpacity = XmlAttr.d(el, 'disabledOpacity', c.startBtnDisabledOpacity);
    c.startBtnImageFit = XmlAttr.s(el, 'imageFit', c.startBtnImageFit);
    c.startBtnImageOffsetH = XmlAttr.d(el, 'imageOffsetH', c.startBtnImageOffsetH);
    c.startBtnImageOffsetV = XmlAttr.d(el, 'imageOffsetV', c.startBtnImageOffsetV);
  }

  static void _applyBackBtn(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.backBtnTop = XmlAttr.d(el, 'top', c.backBtnTop);
    c.backBtnLeft = XmlAttr.d(el, 'left', c.backBtnLeft);
    c.backBtnWidth = XmlAttr.d(el, 'width', c.backBtnWidth);
    c.backBtnHeight = XmlAttr.d(el, 'height', c.backBtnHeight);
    c.backIconSize = XmlAttr.d(el, 'iconSize', c.backIconSize);
    c.backLabelGap = XmlAttr.d(el, 'labelGap', c.backLabelGap);
    c.backLabelFontSize = XmlAttr.d(el, 'labelFontSize', c.backLabelFontSize);
    c.backDisabledOpacity = XmlAttr.d(el, 'disabledOpacity', c.backDisabledOpacity);
    c.backSafeExtra = XmlAttr.d(el, 'safeExtra', c.backSafeExtra);
    c.backBtnImageFit = XmlAttr.s(el, 'imageFit', c.backBtnImageFit);
    c.backBtnImageOffsetH = XmlAttr.d(el, 'imageOffsetH', c.backBtnImageOffsetH);
    c.backBtnImageOffsetV = XmlAttr.d(el, 'imageOffsetV', c.backBtnImageOffsetV);
  }

  static void _applySpiritRoot(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.spiritRootTitleFontSize = XmlAttr.d(el, 'titleFontSize', c.spiritRootTitleFontSize);
    c.spiritRootTitleGap = XmlAttr.d(el, 'titleGap', c.spiritRootTitleGap);
    c.spiritRootTitleBarHeight =
        XmlAttr.d(el, 'titleBarHeight', c.spiritRootTitleBarHeight);
    c.spiritRootTitleBarWidthFraction =
        XmlAttr.d(el, 'titleBarWidthFraction', c.spiritRootTitleBarWidthFraction);
    c.spiritRootTitleImageFit =
        XmlAttr.s(el, 'titleImageFit', c.spiritRootTitleImageFit);
    c.spiritRootTitleImageOffsetH =
        XmlAttr.d(el, 'titleImageOffsetH', c.spiritRootTitleImageOffsetH);
    c.spiritRootTitleImageOffsetV =
        XmlAttr.d(el, 'titleImageOffsetV', c.spiritRootTitleImageOffsetV);
    c.spiritRootItemImageFit = XmlAttr.s(el, 'itemImageFit', c.spiritRootItemImageFit);
    c.spiritRootItemImageOffsetH =
        XmlAttr.d(el, 'itemImageOffsetH', c.spiritRootItemImageOffsetH);
    c.spiritRootItemImageOffsetV =
        XmlAttr.d(el, 'itemImageOffsetV', c.spiritRootItemImageOffsetV);
    c.spiritRootPanelPaddingTop = XmlAttr.d(el, 'panelPaddingTop', c.spiritRootPanelPaddingTop);
    c.spiritRootPanelPaddingH = XmlAttr.d(el, 'panelPaddingH', c.spiritRootPanelPaddingH);
    c.spiritRootIconSize = XmlAttr.d(el, 'iconSize', c.spiritRootIconSize);
    c.spiritRootItemMinHeight = XmlAttr.d(el, 'itemMinHeight', c.spiritRootItemMinHeight);
    c.spiritRootItemMaxHeight = XmlAttr.d(el, 'itemMaxHeight', c.spiritRootItemMaxHeight);
    c.spiritRootItemRadius = XmlAttr.d(el, 'itemRadius', c.spiritRootItemRadius);
    c.spiritRootItemVMargin = XmlAttr.d(el, 'itemVMargin', c.spiritRootItemVMargin);
    c.spiritRootItemSpacing = XmlAttr.d(el, 'itemSpacing', c.spiritRootItemSpacing);
    c.spiritRootItemPadding = XmlAttr.d(el, 'itemPadding', c.spiritRootItemPadding);
    c.spiritRootItemPaddingH = XmlAttr.d(el, 'itemPaddingH', c.spiritRootItemPaddingH);
    c.spiritRootItemPaddingV = XmlAttr.d(el, 'itemPaddingV', c.spiritRootItemPaddingV);
    c.spiritRootUnselectedBgOpacity = XmlAttr.d(el, 'unselectedBgOpacity', c.spiritRootUnselectedBgOpacity);
    c.spiritRootSelectedBgOpacity = XmlAttr.d(el, 'selectedBgOpacity', c.spiritRootSelectedBgOpacity);
    c.spiritRootUnselectedBorderOpacity = XmlAttr.d(el, 'unselectedBorderOpacity', c.spiritRootUnselectedBorderOpacity);
    c.spiritRootUnselectedBorderWidth = XmlAttr.d(el, 'unselectedBorderWidth', c.spiritRootUnselectedBorderWidth);
    c.spiritRootUnselectedHighlightOpacity = XmlAttr.d(el, 'unselectedHighlightOpacity', c.spiritRootUnselectedHighlightOpacity);
    c.spiritRootSelectedBorderOpacity = XmlAttr.d(el, 'selectedBorderOpacity', c.spiritRootSelectedBorderOpacity);
    c.spiritRootSelectedGlowOpacity = XmlAttr.d(el, 'selectedGlowOpacity', c.spiritRootSelectedGlowOpacity);
    c.spiritRootSelectedGlowBlur = XmlAttr.d(el, 'selectedGlowBlur', c.spiritRootSelectedGlowBlur);
    c.spiritRootSelectedGlowSpread = XmlAttr.d(el, 'selectedGlowSpread', c.spiritRootSelectedGlowSpread);
    c.spiritRootSelectedBorderWidth = XmlAttr.d(el, 'selectedBorderWidth', c.spiritRootSelectedBorderWidth);
    c.spiritRootNameFontSize = XmlAttr.d(el, 'nameFontSize', c.spiritRootNameFontSize);
    c.spiritRootDescFontSize = XmlAttr.d(el, 'descFontSize', c.spiritRootDescFontSize);
    c.spiritRootCloudLabelHeight =
        XmlAttr.d(el, 'cloudLabelHeight', c.spiritRootCloudLabelHeight);
    c.spiritRootUnselectedNameColor =
        XmlAttr.colorInt(el, 'unselectedNameColor', c.spiritRootUnselectedNameColor);
    c.spiritRootUnselectedDescColor =
        XmlAttr.colorInt(el, 'unselectedDescColor', c.spiritRootUnselectedDescColor);
  }

  static void _applyNameField(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.nameFieldFontSize = XmlAttr.d(el, 'fontSize', c.nameFieldFontSize);
    c.nameHintFontSize = XmlAttr.d(el, 'hintFontSize', c.nameHintFontSize);
    c.nameHintOpacity = XmlAttr.d(el, 'hintOpacity', c.nameHintOpacity);
    c.nameFieldTextOffsetH = XmlAttr.d(el, 'textOffsetH', c.nameFieldTextOffsetH);
    c.nameFieldTextOffsetV = XmlAttr.d(el, 'textOffsetV', c.nameFieldTextOffsetV);
  }

  static void _applyGender(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.genderSectionPaddingH = XmlAttr.d(el, 'sectionPaddingH', c.genderSectionPaddingH);
    c.genderSectionPaddingV = XmlAttr.d(el, 'sectionPaddingV', c.genderSectionPaddingV);
    c.genderSectionRadius = XmlAttr.d(el, 'sectionRadius', c.genderSectionRadius);
    c.genderSectionBgOpacity = XmlAttr.d(el, 'sectionBgOpacity', c.genderSectionBgOpacity);
    c.genderIconSize = XmlAttr.d(el, 'iconSize', c.genderIconSize);
    c.genderTitleFontSize = XmlAttr.d(el, 'titleFontSize', c.genderTitleFontSize);
    c.genderBtnWidth = XmlAttr.d(el, 'btnWidth', c.genderBtnWidth);
    c.genderBtnHeight = XmlAttr.d(el, 'btnHeight', c.genderBtnHeight);
    c.genderBtnRadius = XmlAttr.d(el, 'btnRadius', c.genderBtnRadius);
    c.genderBtnFontSize = XmlAttr.d(el, 'btnFontSize', c.genderBtnFontSize);
    c.genderBtnImageFit = XmlAttr.s(el, 'imageFit', c.genderBtnImageFit);
    c.genderBtnImageOffsetH = XmlAttr.d(el, 'imageOffsetH', c.genderBtnImageOffsetH);
    c.genderBtnImageOffsetV = XmlAttr.d(el, 'imageOffsetV', c.genderBtnImageOffsetV);
    c.genderUnselectedOverlayOpacity = XmlAttr.d(el, 'unselectedOverlayOpacity', c.genderUnselectedOverlayOpacity);
    c.genderUnselectedTextOpacity = XmlAttr.d(el, 'unselectedTextOpacity', c.genderUnselectedTextOpacity);
    c.genderSelectedBorderWidth = XmlAttr.d(el, 'selectedBorderWidth', c.genderSelectedBorderWidth);
    c.genderBtnGap = XmlAttr.d(el, 'btnGap', c.genderBtnGap);
  }

  static void _applyStats(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.statsSectionPadding = XmlAttr.d(el, 'sectionPadding', c.statsSectionPadding);
    c.statsSectionPaddingTop =
        XmlAttr.d(el, 'sectionPaddingTop', c.statsSectionPaddingTop);
    c.statsTitleGap = XmlAttr.d(el, 'titleGap', c.statsTitleGap);
    c.statsHeaderRowGap = XmlAttr.d(el, 'headerRowGap', c.statsHeaderRowGap);
    c.statsPointsRowGap = XmlAttr.d(el, 'pointsRowGap', c.statsPointsRowGap);
    c.statsGenderGap = XmlAttr.d(el, 'genderGap', c.statsGenderGap);
    c.statsResetGap = XmlAttr.d(el, 'resetGap', c.statsResetGap);
    c.statsTitleBarHeight = XmlAttr.d(el, 'titleBarHeight', c.statsTitleBarHeight);
    c.statsTitleBarWidthFraction =
        XmlAttr.d(el, 'titleBarWidthFraction', c.statsTitleBarWidthFraction);
    c.statsTitleImageFit = XmlAttr.s(el, 'titleImageFit', c.statsTitleImageFit);
    c.statsTitleImageOffsetH =
        XmlAttr.d(el, 'titleImageOffsetH', c.statsTitleImageOffsetH);
    c.statsTitleImageOffsetV =
        XmlAttr.d(el, 'titleImageOffsetV', c.statsTitleImageOffsetV);
    c.statRowImageFit = XmlAttr.s(el, 'rowImageFit', c.statRowImageFit);
    c.statRowImageOffsetH = XmlAttr.d(el, 'rowImageOffsetH', c.statRowImageOffsetH);
    c.statRowImageOffsetV = XmlAttr.d(el, 'rowImageOffsetV', c.statRowImageOffsetV);
    c.resetBtnWidth = XmlAttr.d(el, 'resetBtnWidth', c.resetBtnWidth);
    c.resetBtnHeight = XmlAttr.d(el, 'resetBtnHeight', c.resetBtnHeight);
    c.resetBtnImageFit = XmlAttr.s(el, 'resetBtnImageFit', c.resetBtnImageFit);
    c.resetBtnImageOffsetH =
        XmlAttr.d(el, 'resetBtnImageOffsetH', c.resetBtnImageOffsetH);
    c.resetBtnImageOffsetV =
        XmlAttr.d(el, 'resetBtnImageOffsetV', c.resetBtnImageOffsetV);
    c.statsTitleLineWidth = XmlAttr.d(el, 'titleLineWidth', c.statsTitleLineWidth);
    c.statsTitleLineHeight = XmlAttr.d(el, 'titleLineHeight', c.statsTitleLineHeight);
    c.statsTitleLineGap = XmlAttr.d(el, 'titleLineGap', c.statsTitleLineGap);
    c.statsPointsBarHeight = XmlAttr.d(el, 'pointsBarHeight', c.statsPointsBarHeight);
    c.statsPointsBarWidthFraction =
        XmlAttr.d(el, 'pointsBarWidthFraction', c.statsPointsBarWidthFraction);
    c.statsPointsLabelWidth =
        XmlAttr.d(el, 'pointsLabelWidth', c.statsPointsLabelWidth);
    c.statsPointsLabelHeight =
        XmlAttr.d(el, 'pointsLabelHeight', c.statsPointsLabelHeight);
    c.statsPointsValueGap = XmlAttr.d(el, 'pointsValueGap', c.statsPointsValueGap);
    c.statsResetPointsRowGap =
        XmlAttr.d(el, 'resetPointsRowGap', c.statsResetPointsRowGap);
    c.statsSectionRadius = XmlAttr.d(el, 'sectionRadius', c.statsSectionRadius);
    c.statsSectionBgOpacity = XmlAttr.d(el, 'sectionBgOpacity', c.statsSectionBgOpacity);
    c.statsTitleFontSize = XmlAttr.d(el, 'titleFontSize', c.statsTitleFontSize);
    c.statsPointsFontSize = XmlAttr.d(el, 'pointsFontSize', c.statsPointsFontSize);
    c.statRowHeight = XmlAttr.d(el, 'rowHeight', c.statRowHeight);
    c.statRowVMargin = XmlAttr.d(el, 'rowVMargin', c.statRowVMargin);
    c.statRowPaddingH = XmlAttr.d(el, 'rowPaddingH', c.statRowPaddingH);
    c.statRowWidthFraction = XmlAttr.d(el, 'rowWidthFraction', c.statRowWidthFraction);
    c.statContentPaddingLeft = XmlAttr.d(el, 'contentPaddingLeft', c.statContentPaddingLeft);
    c.statAdjustBtnGap = XmlAttr.d(el, 'adjustBtnGap', c.statAdjustBtnGap);
    c.statAdjustBtnPaddingRight =
        XmlAttr.d(el, 'adjustBtnPaddingRight', c.statAdjustBtnPaddingRight);
    c.statIconLabelGap = XmlAttr.d(el, 'iconLabelGap', c.statIconLabelGap);
    c.statLabelOffsetH = XmlAttr.d(el, 'labelOffsetH', c.statLabelOffsetH);
    c.statIconOffsetH = XmlAttr.d(el, 'iconOffsetH', c.statIconOffsetH);
    c.statIconOffsetV = XmlAttr.d(el, 'iconOffsetV', c.statIconOffsetV);
    c.statIconSize = XmlAttr.d(el, 'iconSize', c.statIconSize);
    c.statLabelFontSize = XmlAttr.d(el, 'labelFontSize', c.statLabelFontSize);
    c.statLabelWidth = XmlAttr.d(el, 'labelWidth', c.statLabelWidth);
    c.statValueLabelGap = XmlAttr.d(el, 'valueLabelGap', c.statValueLabelGap);
    c.statValueWidth = XmlAttr.d(el, 'valueWidth', c.statValueWidth);
    c.statValueFontSize = XmlAttr.d(el, 'valueFontSize', c.statValueFontSize);
    c.statAdjustBtnSize = XmlAttr.d(el, 'adjustBtnSize', c.statAdjustBtnSize);
    c.statAdjustSymbolFontSize =
        XmlAttr.d(el, 'adjustSymbolFontSize', c.statAdjustSymbolFontSize);
    c.statAdjustBtnDisabledOpacity = XmlAttr.d(el, 'adjustBtnDisabledOpacity', c.statAdjustBtnDisabledOpacity);
    c.statBarHeight = XmlAttr.d(el, 'barHeight', c.statBarHeight);
    c.statBarPaddingH = XmlAttr.d(el, 'barPaddingH', c.statBarPaddingH);
    c.resetBtnFontSize = XmlAttr.d(el, 'resetBtnFontSize', c.resetBtnFontSize);
  }

  static void _applyColors(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.colorTitle = XmlAttr.colorInt(el, 'title', c.colorTitle);
    c.colorAccent = XmlAttr.colorInt(el, 'accent', c.colorAccent);
    c.colorGenderTitle = XmlAttr.colorInt(el, 'genderTitle', c.colorGenderTitle);
    c.colorStatLabel = XmlAttr.colorInt(el, 'statLabel', c.colorStatLabel);
  }

  static void _applyOverlays(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.startBtnHoverOverlay = XmlAttr.color(el, 'startBtnHover', c.startBtnHoverOverlay);
    c.startBtnPressedOverlay = XmlAttr.color(el, 'startBtnPressed', c.startBtnPressedOverlay);
    c.backBtnHoverOverlay = XmlAttr.color(el, 'backBtnHover', c.backBtnHoverOverlay);
    c.backBtnPressedOverlay = XmlAttr.color(el, 'backBtnPressed', c.backBtnPressedOverlay);
    c.interactiveHoverOverlay = XmlAttr.color(el, 'interactiveHover', c.interactiveHoverOverlay);
    c.interactivePressedOverlay = XmlAttr.color(el, 'interactivePressed', c.interactivePressedOverlay);
  }

  static void _applyTextShadows(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.btnShadowNormalColor =
        XmlAttr.color(el, 'btnNormalShadow', c.btnShadowNormalColor);
    c.btnShadowNormalBlur = XmlAttr.d(el, 'btnNormalBlur', c.btnShadowNormalBlur);
    c.btnShadowHoverColor =
        XmlAttr.color(el, 'btnHoverShadow', c.btnShadowHoverColor);
    c.btnShadowHoverBlur = XmlAttr.d(el, 'btnHoverBlur', c.btnShadowHoverBlur);
    c.btnShadowPressedColor =
        XmlAttr.color(el, 'btnPressedShadow', c.btnShadowPressedColor);
    c.btnShadowPressedBlur =
        XmlAttr.d(el, 'btnPressedBlur', c.btnShadowPressedBlur);
    c.btnShadowSelectedColor =
        XmlAttr.color(el, 'btnSelectedShadow', c.btnShadowSelectedColor);
    c.btnShadowSelectedBlur =
        XmlAttr.d(el, 'btnSelectedBlur', c.btnShadowSelectedBlur);
  }

  static void _applyCloudTextShadows(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.cloudTextNormalColor =
        XmlAttr.color(el, 'normalColor', c.cloudTextNormalColor);
    c.cloudTextHoverColor = XmlAttr.color(el, 'hoverColor', c.cloudTextHoverColor);
    c.cloudTextPressedColor =
        XmlAttr.color(el, 'pressedColor', c.cloudTextPressedColor);
    c.cloudTextSelectedColor =
        XmlAttr.color(el, 'selectedColor', c.cloudTextSelectedColor);
  }
}
