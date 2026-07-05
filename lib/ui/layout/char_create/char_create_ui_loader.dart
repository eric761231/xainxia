import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

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
    c.designWidth = _d(root, 'designWidth', c.designWidth);
    c.designHeight = _d(root, 'designHeight', c.designHeight);
    c.scaleMin = _d(root, 'scaleMin', c.scaleMin);
    c.scaleMax = _d(root, 'scaleMax', c.scaleMax);
  }

  static void _applyPortrait(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.portraitStackWidthFactor = _d(el, 'stackWidthFactor', c.portraitStackWidthFactor);
    c.portraitStackHeightFactor = _d(el, 'stackHeightFactor', c.portraitStackHeightFactor);
    c.charPortraitBottomOffset = _d(el, 'bottomOffset', c.charPortraitBottomOffset);
    c.charPortraitWidthFraction = _d(el, 'imageWidthFraction', c.charPortraitWidthFraction);
    c.charPortraitWidthMinFraction = _d(el, 'widthMinFraction', c.charPortraitWidthMinFraction);
    c.charPortraitWidthMaxFraction = _d(el, 'widthMaxFraction', c.charPortraitWidthMaxFraction);
  }

  static void _applyScreen(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.screenPaddingH = _d(el, 'paddingH', c.screenPaddingH);
    c.screenPaddingV = _d(el, 'paddingV', c.screenPaddingV);
    c.columnGap = _d(el, 'columnGap', c.columnGap);
    c.screenLeftFlex = _i(el, 'leftFlex', c.screenLeftFlex);
    c.screenCenterFlex = _i(el, 'centerFlex', c.screenCenterFlex);
    c.screenRightFlex = _i(el, 'rightFlex', c.screenRightFlex);
  }

  static void _applyLeftPanel(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.leftPanelWidth = _d(el, 'width', c.leftPanelWidth);
    c.leftPanelWidthMin = _d(el, 'widthMin', c.leftPanelWidthMin);
    c.leftPanelWidthMax = _d(el, 'widthMax', c.leftPanelWidthMax);
    c.leftPanelHeightFraction = _d(el, 'heightFraction', c.leftPanelHeightFraction);
    c.leftPanelTopOffset = _d(el, 'topOffset', c.leftPanelTopOffset);
  }

  static void _applyRightPanel(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.rightPanelWidthFraction = _d(el, 'widthFraction', c.rightPanelWidthFraction);
    c.rightPanelMinWidth = _d(el, 'minWidth', c.rightPanelMinWidth);
    c.rightPanelMaxWidth = _d(el, 'maxWidth', c.rightPanelMaxWidth);
    c.rightPanelHeightFraction = _d(el, 'heightFraction', c.rightPanelHeightFraction);
    c.rightPanelTopOffset = _d(el, 'topOffset', c.rightPanelTopOffset);
  }

  static void _applyNameBar(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.nameBarBottom = _d(el, 'bottom', c.nameBarBottom);
    c.nameBarWidth = _d(el, 'width', c.nameBarWidth);
    c.nameBarMinWidth = _d(el, 'minWidth', c.nameBarMinWidth);
    c.nameBarHeight = _d(el, 'height', c.nameBarHeight);
    c.nameBarPaddingH = _d(el, 'paddingH', c.nameBarPaddingH);
    c.nameBarPaddingV = _d(el, 'paddingV', c.nameBarPaddingV);
    c.nameBarOffsetH = _d(el, 'offsetH', c.nameBarOffsetH);
    c.nameBarImageOffsetH = _d(el, 'imageOffsetH', c.nameBarImageOffsetH);
    c.nameBarImageOffsetV = _d(el, 'imageOffsetV', c.nameBarImageOffsetV);
  }

  static void _applyStartBtn(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.startBtnBottom = _d(el, 'bottom', c.startBtnBottom);
    c.startBtnRight = _d(el, 'right', c.startBtnRight);
    c.startBtnWidth = _d(el, 'width', c.startBtnWidth);
    c.startBtnMaxWidth = _d(el, 'maxWidth', c.startBtnMaxWidth);
    c.startBtnHeight = _d(el, 'height', c.startBtnHeight);
    c.startBtnMaxHeight = _d(el, 'maxHeight', c.startBtnMaxHeight);
    c.startBtnFontSize = _d(el, 'fontSize', c.startBtnFontSize);
    c.startBtnDisabledOpacity = _d(el, 'disabledOpacity', c.startBtnDisabledOpacity);
    c.startBtnImageFit = _s(el, 'imageFit', c.startBtnImageFit);
    c.startBtnImageOffsetH = _d(el, 'imageOffsetH', c.startBtnImageOffsetH);
    c.startBtnImageOffsetV = _d(el, 'imageOffsetV', c.startBtnImageOffsetV);
  }

  static void _applyBackBtn(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.backBtnTop = _d(el, 'top', c.backBtnTop);
    c.backBtnLeft = _d(el, 'left', c.backBtnLeft);
    c.backBtnWidth = _d(el, 'width', c.backBtnWidth);
    c.backBtnHeight = _d(el, 'height', c.backBtnHeight);
    c.backIconSize = _d(el, 'iconSize', c.backIconSize);
    c.backLabelGap = _d(el, 'labelGap', c.backLabelGap);
    c.backLabelFontSize = _d(el, 'labelFontSize', c.backLabelFontSize);
    c.backDisabledOpacity = _d(el, 'disabledOpacity', c.backDisabledOpacity);
    c.backSafeExtra = _d(el, 'safeExtra', c.backSafeExtra);
    c.backBtnImageFit = _s(el, 'imageFit', c.backBtnImageFit);
    c.backBtnImageOffsetH = _d(el, 'imageOffsetH', c.backBtnImageOffsetH);
    c.backBtnImageOffsetV = _d(el, 'imageOffsetV', c.backBtnImageOffsetV);
  }

  static void _applySpiritRoot(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.spiritRootTitleFontSize = _d(el, 'titleFontSize', c.spiritRootTitleFontSize);
    c.spiritRootTitleGap = _d(el, 'titleGap', c.spiritRootTitleGap);
    c.spiritRootTitleBarHeight =
        _d(el, 'titleBarHeight', c.spiritRootTitleBarHeight);
    c.spiritRootTitleBarWidthFraction =
        _d(el, 'titleBarWidthFraction', c.spiritRootTitleBarWidthFraction);
    c.spiritRootTitleImageFit =
        _s(el, 'titleImageFit', c.spiritRootTitleImageFit);
    c.spiritRootTitleImageOffsetH =
        _d(el, 'titleImageOffsetH', c.spiritRootTitleImageOffsetH);
    c.spiritRootTitleImageOffsetV =
        _d(el, 'titleImageOffsetV', c.spiritRootTitleImageOffsetV);
    c.spiritRootItemImageFit = _s(el, 'itemImageFit', c.spiritRootItemImageFit);
    c.spiritRootItemImageOffsetH =
        _d(el, 'itemImageOffsetH', c.spiritRootItemImageOffsetH);
    c.spiritRootItemImageOffsetV =
        _d(el, 'itemImageOffsetV', c.spiritRootItemImageOffsetV);
    c.spiritRootPanelPaddingTop = _d(el, 'panelPaddingTop', c.spiritRootPanelPaddingTop);
    c.spiritRootPanelPaddingH = _d(el, 'panelPaddingH', c.spiritRootPanelPaddingH);
    c.spiritRootIconSize = _d(el, 'iconSize', c.spiritRootIconSize);
    c.spiritRootItemMinHeight = _d(el, 'itemMinHeight', c.spiritRootItemMinHeight);
    c.spiritRootItemMaxHeight = _d(el, 'itemMaxHeight', c.spiritRootItemMaxHeight);
    c.spiritRootItemRadius = _d(el, 'itemRadius', c.spiritRootItemRadius);
    c.spiritRootItemVMargin = _d(el, 'itemVMargin', c.spiritRootItemVMargin);
    c.spiritRootItemSpacing = _d(el, 'itemSpacing', c.spiritRootItemSpacing);
    c.spiritRootItemPadding = _d(el, 'itemPadding', c.spiritRootItemPadding);
    c.spiritRootItemPaddingH = _d(el, 'itemPaddingH', c.spiritRootItemPaddingH);
    c.spiritRootItemPaddingV = _d(el, 'itemPaddingV', c.spiritRootItemPaddingV);
    c.spiritRootUnselectedBgOpacity = _d(el, 'unselectedBgOpacity', c.spiritRootUnselectedBgOpacity);
    c.spiritRootSelectedBgOpacity = _d(el, 'selectedBgOpacity', c.spiritRootSelectedBgOpacity);
    c.spiritRootUnselectedBorderOpacity = _d(el, 'unselectedBorderOpacity', c.spiritRootUnselectedBorderOpacity);
    c.spiritRootUnselectedBorderWidth = _d(el, 'unselectedBorderWidth', c.spiritRootUnselectedBorderWidth);
    c.spiritRootUnselectedHighlightOpacity = _d(el, 'unselectedHighlightOpacity', c.spiritRootUnselectedHighlightOpacity);
    c.spiritRootSelectedBorderOpacity = _d(el, 'selectedBorderOpacity', c.spiritRootSelectedBorderOpacity);
    c.spiritRootSelectedGlowOpacity = _d(el, 'selectedGlowOpacity', c.spiritRootSelectedGlowOpacity);
    c.spiritRootSelectedGlowBlur = _d(el, 'selectedGlowBlur', c.spiritRootSelectedGlowBlur);
    c.spiritRootSelectedGlowSpread = _d(el, 'selectedGlowSpread', c.spiritRootSelectedGlowSpread);
    c.spiritRootSelectedBorderWidth = _d(el, 'selectedBorderWidth', c.spiritRootSelectedBorderWidth);
    c.spiritRootNameFontSize = _d(el, 'nameFontSize', c.spiritRootNameFontSize);
    c.spiritRootDescFontSize = _d(el, 'descFontSize', c.spiritRootDescFontSize);
    c.spiritRootCloudLabelHeight =
        _d(el, 'cloudLabelHeight', c.spiritRootCloudLabelHeight);
    c.spiritRootUnselectedNameColor =
        _colorInt(el, 'unselectedNameColor', c.spiritRootUnselectedNameColor);
    c.spiritRootUnselectedDescColor =
        _colorInt(el, 'unselectedDescColor', c.spiritRootUnselectedDescColor);
  }

  static void _applyNameField(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.nameFieldFontSize = _d(el, 'fontSize', c.nameFieldFontSize);
    c.nameHintFontSize = _d(el, 'hintFontSize', c.nameHintFontSize);
    c.nameHintOpacity = _d(el, 'hintOpacity', c.nameHintOpacity);
    c.nameFieldTextOffsetH = _d(el, 'textOffsetH', c.nameFieldTextOffsetH);
    c.nameFieldTextOffsetV = _d(el, 'textOffsetV', c.nameFieldTextOffsetV);
  }

  static void _applyGender(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.genderSectionPaddingH = _d(el, 'sectionPaddingH', c.genderSectionPaddingH);
    c.genderSectionPaddingV = _d(el, 'sectionPaddingV', c.genderSectionPaddingV);
    c.genderSectionRadius = _d(el, 'sectionRadius', c.genderSectionRadius);
    c.genderSectionBgOpacity = _d(el, 'sectionBgOpacity', c.genderSectionBgOpacity);
    c.genderIconSize = _d(el, 'iconSize', c.genderIconSize);
    c.genderTitleFontSize = _d(el, 'titleFontSize', c.genderTitleFontSize);
    c.genderBtnWidth = _d(el, 'btnWidth', c.genderBtnWidth);
    c.genderBtnHeight = _d(el, 'btnHeight', c.genderBtnHeight);
    c.genderBtnRadius = _d(el, 'btnRadius', c.genderBtnRadius);
    c.genderBtnFontSize = _d(el, 'btnFontSize', c.genderBtnFontSize);
    c.genderBtnImageFit = _s(el, 'imageFit', c.genderBtnImageFit);
    c.genderBtnImageOffsetH = _d(el, 'imageOffsetH', c.genderBtnImageOffsetH);
    c.genderBtnImageOffsetV = _d(el, 'imageOffsetV', c.genderBtnImageOffsetV);
    c.genderUnselectedOverlayOpacity = _d(el, 'unselectedOverlayOpacity', c.genderUnselectedOverlayOpacity);
    c.genderUnselectedTextOpacity = _d(el, 'unselectedTextOpacity', c.genderUnselectedTextOpacity);
    c.genderSelectedBorderWidth = _d(el, 'selectedBorderWidth', c.genderSelectedBorderWidth);
    c.genderBtnGap = _d(el, 'btnGap', c.genderBtnGap);
  }

  static void _applyStats(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.statsSectionPadding = _d(el, 'sectionPadding', c.statsSectionPadding);
    c.statsSectionPaddingTop =
        _d(el, 'sectionPaddingTop', c.statsSectionPaddingTop);
    c.statsTitleGap = _d(el, 'titleGap', c.statsTitleGap);
    c.statsHeaderRowGap = _d(el, 'headerRowGap', c.statsHeaderRowGap);
    c.statsPointsRowGap = _d(el, 'pointsRowGap', c.statsPointsRowGap);
    c.statsGenderGap = _d(el, 'genderGap', c.statsGenderGap);
    c.statsResetGap = _d(el, 'resetGap', c.statsResetGap);
    c.statsTitleBarHeight = _d(el, 'titleBarHeight', c.statsTitleBarHeight);
    c.statsTitleBarWidthFraction =
        _d(el, 'titleBarWidthFraction', c.statsTitleBarWidthFraction);
    c.statsTitleImageFit = _s(el, 'titleImageFit', c.statsTitleImageFit);
    c.statsTitleImageOffsetH =
        _d(el, 'titleImageOffsetH', c.statsTitleImageOffsetH);
    c.statsTitleImageOffsetV =
        _d(el, 'titleImageOffsetV', c.statsTitleImageOffsetV);
    c.statRowImageFit = _s(el, 'rowImageFit', c.statRowImageFit);
    c.statRowImageOffsetH = _d(el, 'rowImageOffsetH', c.statRowImageOffsetH);
    c.statRowImageOffsetV = _d(el, 'rowImageOffsetV', c.statRowImageOffsetV);
    c.resetBtnWidth = _d(el, 'resetBtnWidth', c.resetBtnWidth);
    c.resetBtnHeight = _d(el, 'resetBtnHeight', c.resetBtnHeight);
    c.resetBtnImageFit = _s(el, 'resetBtnImageFit', c.resetBtnImageFit);
    c.resetBtnImageOffsetH =
        _d(el, 'resetBtnImageOffsetH', c.resetBtnImageOffsetH);
    c.resetBtnImageOffsetV =
        _d(el, 'resetBtnImageOffsetV', c.resetBtnImageOffsetV);
    c.statsTitleLineWidth = _d(el, 'titleLineWidth', c.statsTitleLineWidth);
    c.statsTitleLineHeight = _d(el, 'titleLineHeight', c.statsTitleLineHeight);
    c.statsTitleLineGap = _d(el, 'titleLineGap', c.statsTitleLineGap);
    c.statsPointsBarHeight = _d(el, 'pointsBarHeight', c.statsPointsBarHeight);
    c.statsPointsBarWidthFraction =
        _d(el, 'pointsBarWidthFraction', c.statsPointsBarWidthFraction);
    c.statsPointsLabelWidth =
        _d(el, 'pointsLabelWidth', c.statsPointsLabelWidth);
    c.statsPointsLabelHeight =
        _d(el, 'pointsLabelHeight', c.statsPointsLabelHeight);
    c.statsPointsValueGap = _d(el, 'pointsValueGap', c.statsPointsValueGap);
    c.statsResetPointsRowGap =
        _d(el, 'resetPointsRowGap', c.statsResetPointsRowGap);
    c.statsSectionRadius = _d(el, 'sectionRadius', c.statsSectionRadius);
    c.statsSectionBgOpacity = _d(el, 'sectionBgOpacity', c.statsSectionBgOpacity);
    c.statsTitleFontSize = _d(el, 'titleFontSize', c.statsTitleFontSize);
    c.statsPointsFontSize = _d(el, 'pointsFontSize', c.statsPointsFontSize);
    c.statRowHeight = _d(el, 'rowHeight', c.statRowHeight);
    c.statRowVMargin = _d(el, 'rowVMargin', c.statRowVMargin);
    c.statRowPaddingH = _d(el, 'rowPaddingH', c.statRowPaddingH);
    c.statRowWidthFraction = _d(el, 'rowWidthFraction', c.statRowWidthFraction);
    c.statContentPaddingLeft = _d(el, 'contentPaddingLeft', c.statContentPaddingLeft);
    c.statAdjustBtnGap = _d(el, 'adjustBtnGap', c.statAdjustBtnGap);
    c.statAdjustBtnPaddingRight =
        _d(el, 'adjustBtnPaddingRight', c.statAdjustBtnPaddingRight);
    c.statIconLabelGap = _d(el, 'iconLabelGap', c.statIconLabelGap);
    c.statLabelOffsetH = _d(el, 'labelOffsetH', c.statLabelOffsetH);
    c.statIconOffsetH = _d(el, 'iconOffsetH', c.statIconOffsetH);
    c.statIconOffsetV = _d(el, 'iconOffsetV', c.statIconOffsetV);
    c.statIconSize = _d(el, 'iconSize', c.statIconSize);
    c.statLabelFontSize = _d(el, 'labelFontSize', c.statLabelFontSize);
    c.statLabelWidth = _d(el, 'labelWidth', c.statLabelWidth);
    c.statValueLabelGap = _d(el, 'valueLabelGap', c.statValueLabelGap);
    c.statValueWidth = _d(el, 'valueWidth', c.statValueWidth);
    c.statValueFontSize = _d(el, 'valueFontSize', c.statValueFontSize);
    c.statAdjustBtnSize = _d(el, 'adjustBtnSize', c.statAdjustBtnSize);
    c.statAdjustSymbolFontSize =
        _d(el, 'adjustSymbolFontSize', c.statAdjustSymbolFontSize);
    c.statAdjustBtnDisabledOpacity = _d(el, 'adjustBtnDisabledOpacity', c.statAdjustBtnDisabledOpacity);
    c.statBarHeight = _d(el, 'barHeight', c.statBarHeight);
    c.statBarPaddingH = _d(el, 'barPaddingH', c.statBarPaddingH);
    c.resetBtnFontSize = _d(el, 'resetBtnFontSize', c.resetBtnFontSize);
  }

  static void _applyColors(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.colorTitle = _colorInt(el, 'title', c.colorTitle);
    c.colorAccent = _colorInt(el, 'accent', c.colorAccent);
    c.colorGenderTitle = _colorInt(el, 'genderTitle', c.colorGenderTitle);
    c.colorStatLabel = _colorInt(el, 'statLabel', c.colorStatLabel);
  }

  static void _applyOverlays(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.startBtnHoverOverlay = _color(el, 'startBtnHover', c.startBtnHoverOverlay);
    c.startBtnPressedOverlay = _color(el, 'startBtnPressed', c.startBtnPressedOverlay);
    c.backBtnHoverOverlay = _color(el, 'backBtnHover', c.backBtnHoverOverlay);
    c.backBtnPressedOverlay = _color(el, 'backBtnPressed', c.backBtnPressedOverlay);
    c.interactiveHoverOverlay = _color(el, 'interactiveHover', c.interactiveHoverOverlay);
    c.interactivePressedOverlay = _color(el, 'interactivePressed', c.interactivePressedOverlay);
  }

  static void _applyTextShadows(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.btnShadowNormalColor =
        _color(el, 'btnNormalShadow', c.btnShadowNormalColor);
    c.btnShadowNormalBlur = _d(el, 'btnNormalBlur', c.btnShadowNormalBlur);
    c.btnShadowHoverColor =
        _color(el, 'btnHoverShadow', c.btnShadowHoverColor);
    c.btnShadowHoverBlur = _d(el, 'btnHoverBlur', c.btnShadowHoverBlur);
    c.btnShadowPressedColor =
        _color(el, 'btnPressedShadow', c.btnShadowPressedColor);
    c.btnShadowPressedBlur =
        _d(el, 'btnPressedBlur', c.btnShadowPressedBlur);
    c.btnShadowSelectedColor =
        _color(el, 'btnSelectedShadow', c.btnShadowSelectedColor);
    c.btnShadowSelectedBlur =
        _d(el, 'btnSelectedBlur', c.btnShadowSelectedBlur);
  }

  static void _applyCloudTextShadows(CharCreateUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.cloudTextNormalColor =
        _color(el, 'normalColor', c.cloudTextNormalColor);
    c.cloudTextHoverColor = _color(el, 'hoverColor', c.cloudTextHoverColor);
    c.cloudTextPressedColor =
        _color(el, 'pressedColor', c.cloudTextPressedColor);
    c.cloudTextSelectedColor =
        _color(el, 'selectedColor', c.cloudTextSelectedColor);
  }

  static double _d(XmlElement el, String name, double fallback) {
    final raw = el.getAttribute(name);
    if (raw == null) return fallback;
    return double.tryParse(raw) ?? fallback;
  }

  static String _s(XmlElement el, String name, String fallback) {
    final raw = el.getAttribute(name);
    if (raw == null || raw.isEmpty) return fallback;
    return raw;
  }

  static int _i(XmlElement el, String name, int fallback) {
    final raw = el.getAttribute(name);
    if (raw == null) return fallback;
    return int.tryParse(raw) ?? fallback;
  }

  static int _colorInt(XmlElement el, String name, int fallback) {
    final raw = el.getAttribute(name);
    if (raw == null) return fallback;
    final parsed = int.tryParse(raw, radix: 16);
    return parsed ?? fallback;
  }

  static Color _color(XmlElement el, String name, Color fallback) {
    final raw = el.getAttribute(name);
    if (raw == null || !raw.startsWith('#')) return fallback;
    final hex = raw.substring(1);
    if (hex.length == 8) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(v);
    }
    if (hex.length == 6) {
      final v = int.tryParse('FF$hex', radix: 16);
      if (v != null) return Color(v);
    }
    return fallback;
  }
}
