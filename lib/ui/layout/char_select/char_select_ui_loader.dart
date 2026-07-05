import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import 'char_select_ui_config.dart';
import '../char_create/char_create_ui_source_stub.dart'
    if (dart.library.io) '../char_create/char_create_ui_source_io.dart';

/// 從 [CharSelectUiLoader.assetPath] 載入角色選擇 UI 配置。
abstract final class CharSelectUiLoader {
  static const assetPath = 'assets/ui/layouts/char_select_layout.xml';

  static Future<CharSelectUiConfig> load() async {
    final config = CharSelectUiConfig();
    try {
      final raw = await readDebugAssetFile(assetPath) ??
          await rootBundle.loadString(assetPath);
      _applyXml(config, XmlDocument.parse(raw).rootElement);
    } catch (_) {
      // 缺檔或解析失敗時使用 CharSelectUiConfig 內建預設值。
    }
    return config;
  }

  static void _applyXml(CharSelectUiConfig c, XmlElement root) {
    _applyRoot(c, root);
    final layout = root.getElement('layout');
    if (layout != null) {
      _applyTopBar(c, layout.getElement('topBar'));
      _applyLeftPanel(c, layout.getElement('leftPanel'));
      _applyCenterPanel(c, layout.getElement('centerPanel'));
      _applyRightPanel(c, layout.getElement('rightPanel'));
      _applyBottomBar(c, layout.getElement('bottomBar'));
    }
    final styles = root.getElement('styles');
    if (styles != null) {
      _applyCharCard(c, styles.getElement('charCard'));
      _applyInfoPanel(c, styles.getElement('infoPanel'));
      _applyColors(c, styles.getElement('colors'));
      _applyOverlays(c, styles.getElement('overlays'));
    }
  }

  static void _applyRoot(CharSelectUiConfig c, XmlElement root) {
    c.designWidth = _d(root, 'designWidth', c.designWidth);
    c.designHeight = _d(root, 'designHeight', c.designHeight);
    c.scaleMin = _d(root, 'scaleMin', c.scaleMin);
    c.scaleMax = _d(root, 'scaleMax', c.scaleMax);
  }

  static void _applyTopBar(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.topBarHeight = _d(el, 'height', c.topBarHeight);
    c.topBarPaddingH = _d(el, 'paddingH', c.topBarPaddingH);
    c.topBarPaddingV = _d(el, 'paddingV', c.topBarPaddingV);
    c.topBarTitleFontSize = _d(el, 'titleFontSize', c.topBarTitleFontSize);
    c.topBarBackBtnWidth = _d(el, 'backBtnWidth', c.topBarBackBtnWidth);
    c.topBarBackBtnHeight = _d(el, 'backBtnHeight', c.topBarBackBtnHeight);
    c.topBarBackIconSize = _d(el, 'backIconSize', c.topBarBackIconSize);
    c.topBarBackLabelFontSize = _d(el, 'backLabelFontSize', c.topBarBackLabelFontSize);
    c.topBarSlotFontSize = _d(el, 'slotFontSize', c.topBarSlotFontSize);
  }

  static void _applyLeftPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.leftPanelWidth = _d(el, 'width', c.leftPanelWidth);
    c.leftPanelWidthMin = _d(el, 'widthMin', c.leftPanelWidthMin);
    c.leftPanelWidthMax = _d(el, 'widthMax', c.leftPanelWidthMax);
    c.leftPanelTopOffset = _d(el, 'topOffset', c.leftPanelTopOffset);
    c.leftPanelPaddingH = _d(el, 'paddingH', c.leftPanelPaddingH);
    c.leftPanelListSpacing = _d(el, 'listSpacing', c.leftPanelListSpacing);
  }

  static void _applyCenterPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.centerPortraitWidthFraction = _d(el, 'portraitWidthFraction', c.centerPortraitWidthFraction);
    c.centerPortraitBottomOffset = _d(el, 'portraitBottomOffset', c.centerPortraitBottomOffset);
    c.centerNameFontSize = _d(el, 'nameFontSize', c.centerNameFontSize);
    c.centerLevelFontSize = _d(el, 'levelFontSize', c.centerLevelFontSize);
    c.centerNamePaddingH = _d(el, 'namePaddingH', c.centerNamePaddingH);
  }

  static void _applyRightPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.rightPanelWidthFraction = _d(el, 'widthFraction', c.rightPanelWidthFraction);
    c.rightPanelMinWidth = _d(el, 'minWidth', c.rightPanelMinWidth);
    c.rightPanelMaxWidth = _d(el, 'maxWidth', c.rightPanelMaxWidth);
    c.rightPanelTopOffset = _d(el, 'topOffset', c.rightPanelTopOffset);
    c.rightPanelPaddingH = _d(el, 'paddingH', c.rightPanelPaddingH);
    c.rightPanelPaddingV = _d(el, 'paddingV', c.rightPanelPaddingV);
    c.rightPanelSectionGap = _d(el, 'sectionGap', c.rightPanelSectionGap);
    c.rightPanelSectionRadius = _d(el, 'sectionRadius', c.rightPanelSectionRadius);
    c.rightPanelSectionBgOpacity = _d(el, 'sectionBgOpacity', c.rightPanelSectionBgOpacity);
  }

  static void _applyBottomBar(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.bottomBarHeight = _d(el, 'height', c.bottomBarHeight);
    c.bottomBarPaddingH = _d(el, 'paddingH', c.bottomBarPaddingH);
    c.bottomBarPaddingV = _d(el, 'paddingV', c.bottomBarPaddingV);
    c.bottomBarBtnHeight = _d(el, 'btnHeight', c.bottomBarBtnHeight);
    c.bottomBarBtnRadius = _d(el, 'btnRadius', c.bottomBarBtnRadius);
    c.bottomBarEnterBtnWidth = _d(el, 'enterBtnWidth', c.bottomBarEnterBtnWidth);
    c.bottomBarSideBtnWidth = _d(el, 'sideBtnWidth', c.bottomBarSideBtnWidth);
    c.bottomBarFontSize = _d(el, 'fontSize', c.bottomBarFontSize);
  }

  static void _applyCharCard(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.cardHeight = _d(el, 'cardHeight', c.cardHeight);
    c.cardRadius = _d(el, 'cardRadius', c.cardRadius);
    c.cardPaddingH = _d(el, 'cardPaddingH', c.cardPaddingH);
    c.cardPaddingV = _d(el, 'cardPaddingV', c.cardPaddingV);
    c.cardIconSize = _d(el, 'iconSize', c.cardIconSize);
    c.cardIconRadius = _d(el, 'iconRadius', c.cardIconRadius);
    c.cardNameGap = _d(el, 'nameGap', c.cardNameGap);
    c.cardNameFontSize = _d(el, 'nameFontSize', c.cardNameFontSize);
    c.cardLevelFontSize = _d(el, 'levelFontSize', c.cardLevelFontSize);
    c.cardAttrIconSize = _d(el, 'attrIconSize', c.cardAttrIconSize);
    c.cardUnselectedBgOpacity = _d(el, 'unselectedBgOpacity', c.cardUnselectedBgOpacity);
    c.cardSelectedBgOpacity = _d(el, 'selectedBgOpacity', c.cardSelectedBgOpacity);
    c.cardUnselectedBorderOpacity = _d(el, 'unselectedBorderOpacity', c.cardUnselectedBorderOpacity);
    c.cardUnselectedBorderWidth = _d(el, 'unselectedBorderWidth', c.cardUnselectedBorderWidth);
    c.cardSelectedBorderOpacity = _d(el, 'selectedBorderOpacity', c.cardSelectedBorderOpacity);
    c.cardSelectedBorderWidth = _d(el, 'selectedBorderWidth', c.cardSelectedBorderWidth);
    c.cardSelectedGlowOpacity = _d(el, 'selectedGlowOpacity', c.cardSelectedGlowOpacity);
    c.cardSelectedGlowBlur = _d(el, 'selectedGlowBlur', c.cardSelectedGlowBlur);
  }

  static void _applyInfoPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.infoPanelTitleBarHeight = _d(el, 'titleBarHeight', c.infoPanelTitleBarHeight);
    c.infoPanelTitleFontSize = _d(el, 'titleFontSize', c.infoPanelTitleFontSize);
    c.infoPanelTitleBarWidthFraction = _d(el, 'titleBarWidthFraction', c.infoPanelTitleBarWidthFraction);
    c.infoPanelPortraitSize = _d(el, 'portraitSize', c.infoPanelPortraitSize);
    c.infoPanelPortraitRadius = _d(el, 'portraitRadius', c.infoPanelPortraitRadius);
    c.infoPanelNameFontSize = _d(el, 'nameFontSize', c.infoPanelNameFontSize);
    c.infoPanelLevelBadgePaddingH = _d(el, 'levelBadgePaddingH', c.infoPanelLevelBadgePaddingH);
    c.infoPanelLevelBadgePaddingV = _d(el, 'levelBadgePaddingV', c.infoPanelLevelBadgePaddingV);
    c.infoPanelLevelBadgeRadius = _d(el, 'levelBadgeRadius', c.infoPanelLevelBadgeRadius);
    c.infoPanelLevelBadgeFontSize = _d(el, 'levelBadgeFontSize', c.infoPanelLevelBadgeFontSize);
    c.infoPanelLabelFontSize = _d(el, 'labelFontSize', c.infoPanelLabelFontSize);
    c.infoPanelValueFontSize = _d(el, 'valueFontSize', c.infoPanelValueFontSize);
    c.infoPanelAttrIconSize = _d(el, 'attrIconSize', c.infoPanelAttrIconSize);
    c.infoPanelRowHeight = _d(el, 'rowHeight', c.infoPanelRowHeight);
    c.infoPanelRowSpacing = _d(el, 'rowSpacing', c.infoPanelRowSpacing);
  }

  static void _applyColors(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.colorAccent = _argb(el, 'accent', c.colorAccent);
    c.colorTitle = _argb(el, 'title', c.colorTitle);
    c.colorLabel = _argb(el, 'label', c.colorLabel);
    c.colorDanger = _argb(el, 'danger', c.colorDanger);
    c.colorCardName = _argb(el, 'cardName', c.colorCardName);
    c.colorCardLevel = _argb(el, 'cardLevel', c.colorCardLevel);
  }

  static void _applyOverlays(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.enterBtnHoverOverlay = _color(el, 'enterBtnHover', c.enterBtnHoverOverlay);
    c.enterBtnPressedOverlay = _color(el, 'enterBtnPressed', c.enterBtnPressedOverlay);
    c.createBtnHoverOverlay = _color(el, 'createBtnHover', c.createBtnHoverOverlay);
    c.createBtnPressedOverlay = _color(el, 'createBtnPressed', c.createBtnPressedOverlay);
    c.deleteBtnHoverOverlay = _color(el, 'deleteBtnHover', c.deleteBtnHoverOverlay);
    c.deleteBtnPressedOverlay = _color(el, 'deleteBtnPressed', c.deleteBtnPressedOverlay);
    c.backBtnHoverOverlay = _color(el, 'backBtnHover', c.backBtnHoverOverlay);
    c.backBtnPressedOverlay = _color(el, 'backBtnPressed', c.backBtnPressedOverlay);
    c.cardHoverOverlay = _color(el, 'cardHover', c.cardHoverOverlay);
    c.cardPressedOverlay = _color(el, 'cardPressed', c.cardPressedOverlay);
  }

  // ── 解析工具 ─────────────────────────────────────────────────

  static double _d(XmlElement el, String attr, double fallback) {
    final v = el.getAttribute(attr);
    if (v == null) return fallback;
    return double.tryParse(v) ?? fallback;
  }

  static int _argb(XmlElement el, String attr, int fallback) {
    final v = el.getAttribute(attr);
    if (v == null) return fallback;
    final hex = v.replaceFirst('#', '');
    return int.tryParse(hex, radix: 16) ?? fallback;
  }

  static Color _color(XmlElement el, String attr, Color fallback) {
    final v = el.getAttribute(attr);
    if (v == null) return fallback;
    final hex = v.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return fallback;
    return hex.length == 6 ? Color(0xFF000000 | value) : Color(value);
  }
}
