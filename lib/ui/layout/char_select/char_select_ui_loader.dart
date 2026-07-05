import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import '../xml_attr.dart';

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
    c.designWidth = XmlAttr.d(root, 'designWidth', c.designWidth);
    c.designHeight = XmlAttr.d(root, 'designHeight', c.designHeight);
    c.scaleMin = XmlAttr.d(root, 'scaleMin', c.scaleMin);
    c.scaleMax = XmlAttr.d(root, 'scaleMax', c.scaleMax);
  }

  static void _applyTopBar(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.topBarHeight = XmlAttr.d(el, 'height', c.topBarHeight);
    c.topBarPaddingH = XmlAttr.d(el, 'paddingH', c.topBarPaddingH);
    c.topBarPaddingV = XmlAttr.d(el, 'paddingV', c.topBarPaddingV);
    c.topBarTitleFontSize = XmlAttr.d(el, 'titleFontSize', c.topBarTitleFontSize);
    c.topBarBackBtnWidth = XmlAttr.d(el, 'backBtnWidth', c.topBarBackBtnWidth);
    c.topBarBackBtnHeight = XmlAttr.d(el, 'backBtnHeight', c.topBarBackBtnHeight);
    c.topBarBackIconSize = XmlAttr.d(el, 'backIconSize', c.topBarBackIconSize);
    c.topBarBackLabelFontSize = XmlAttr.d(el, 'backLabelFontSize', c.topBarBackLabelFontSize);
    c.topBarSlotFontSize = XmlAttr.d(el, 'slotFontSize', c.topBarSlotFontSize);
  }

  static void _applyLeftPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.leftPanelWidth = XmlAttr.d(el, 'width', c.leftPanelWidth);
    c.leftPanelWidthMin = XmlAttr.d(el, 'widthMin', c.leftPanelWidthMin);
    c.leftPanelWidthMax = XmlAttr.d(el, 'widthMax', c.leftPanelWidthMax);
    c.leftPanelTopOffset = XmlAttr.d(el, 'topOffset', c.leftPanelTopOffset);
    c.leftPanelPaddingH = XmlAttr.d(el, 'paddingH', c.leftPanelPaddingH);
    c.leftPanelListSpacing = XmlAttr.d(el, 'listSpacing', c.leftPanelListSpacing);
  }

  static void _applyCenterPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.centerPortraitWidthFraction = XmlAttr.d(el, 'portraitWidthFraction', c.centerPortraitWidthFraction);
    c.centerPortraitBottomOffset = XmlAttr.d(el, 'portraitBottomOffset', c.centerPortraitBottomOffset);
    c.centerNameFontSize = XmlAttr.d(el, 'nameFontSize', c.centerNameFontSize);
    c.centerLevelFontSize = XmlAttr.d(el, 'levelFontSize', c.centerLevelFontSize);
    c.centerNamePaddingH = XmlAttr.d(el, 'namePaddingH', c.centerNamePaddingH);
  }

  static void _applyRightPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.rightPanelWidthFraction = XmlAttr.d(el, 'widthFraction', c.rightPanelWidthFraction);
    c.rightPanelMinWidth = XmlAttr.d(el, 'minWidth', c.rightPanelMinWidth);
    c.rightPanelMaxWidth = XmlAttr.d(el, 'maxWidth', c.rightPanelMaxWidth);
    c.rightPanelTopOffset = XmlAttr.d(el, 'topOffset', c.rightPanelTopOffset);
    c.rightPanelPaddingH = XmlAttr.d(el, 'paddingH', c.rightPanelPaddingH);
    c.rightPanelPaddingV = XmlAttr.d(el, 'paddingV', c.rightPanelPaddingV);
    c.rightPanelSectionGap = XmlAttr.d(el, 'sectionGap', c.rightPanelSectionGap);
    c.rightPanelSectionRadius = XmlAttr.d(el, 'sectionRadius', c.rightPanelSectionRadius);
    c.rightPanelSectionBgOpacity = XmlAttr.d(el, 'sectionBgOpacity', c.rightPanelSectionBgOpacity);
  }

  static void _applyBottomBar(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.bottomBarHeight = XmlAttr.d(el, 'height', c.bottomBarHeight);
    c.bottomBarPaddingH = XmlAttr.d(el, 'paddingH', c.bottomBarPaddingH);
    c.bottomBarPaddingV = XmlAttr.d(el, 'paddingV', c.bottomBarPaddingV);
    c.bottomBarBtnHeight = XmlAttr.d(el, 'btnHeight', c.bottomBarBtnHeight);
    c.bottomBarBtnRadius = XmlAttr.d(el, 'btnRadius', c.bottomBarBtnRadius);
    c.bottomBarEnterBtnWidth = XmlAttr.d(el, 'enterBtnWidth', c.bottomBarEnterBtnWidth);
    c.bottomBarSideBtnWidth = XmlAttr.d(el, 'sideBtnWidth', c.bottomBarSideBtnWidth);
    c.bottomBarFontSize = XmlAttr.d(el, 'fontSize', c.bottomBarFontSize);
  }

  static void _applyCharCard(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.cardHeight = XmlAttr.d(el, 'cardHeight', c.cardHeight);
    c.cardRadius = XmlAttr.d(el, 'cardRadius', c.cardRadius);
    c.cardPaddingH = XmlAttr.d(el, 'cardPaddingH', c.cardPaddingH);
    c.cardPaddingV = XmlAttr.d(el, 'cardPaddingV', c.cardPaddingV);
    c.cardIconSize = XmlAttr.d(el, 'iconSize', c.cardIconSize);
    c.cardIconRadius = XmlAttr.d(el, 'iconRadius', c.cardIconRadius);
    c.cardNameGap = XmlAttr.d(el, 'nameGap', c.cardNameGap);
    c.cardNameFontSize = XmlAttr.d(el, 'nameFontSize', c.cardNameFontSize);
    c.cardLevelFontSize = XmlAttr.d(el, 'levelFontSize', c.cardLevelFontSize);
    c.cardAttrIconSize = XmlAttr.d(el, 'attrIconSize', c.cardAttrIconSize);
    c.cardUnselectedBgOpacity = XmlAttr.d(el, 'unselectedBgOpacity', c.cardUnselectedBgOpacity);
    c.cardSelectedBgOpacity = XmlAttr.d(el, 'selectedBgOpacity', c.cardSelectedBgOpacity);
    c.cardUnselectedBorderOpacity = XmlAttr.d(el, 'unselectedBorderOpacity', c.cardUnselectedBorderOpacity);
    c.cardUnselectedBorderWidth = XmlAttr.d(el, 'unselectedBorderWidth', c.cardUnselectedBorderWidth);
    c.cardSelectedBorderOpacity = XmlAttr.d(el, 'selectedBorderOpacity', c.cardSelectedBorderOpacity);
    c.cardSelectedBorderWidth = XmlAttr.d(el, 'selectedBorderWidth', c.cardSelectedBorderWidth);
    c.cardSelectedGlowOpacity = XmlAttr.d(el, 'selectedGlowOpacity', c.cardSelectedGlowOpacity);
    c.cardSelectedGlowBlur = XmlAttr.d(el, 'selectedGlowBlur', c.cardSelectedGlowBlur);
  }

  static void _applyInfoPanel(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.infoPanelTitleBarHeight = XmlAttr.d(el, 'titleBarHeight', c.infoPanelTitleBarHeight);
    c.infoPanelTitleFontSize = XmlAttr.d(el, 'titleFontSize', c.infoPanelTitleFontSize);
    c.infoPanelTitleBarWidthFraction = XmlAttr.d(el, 'titleBarWidthFraction', c.infoPanelTitleBarWidthFraction);
    c.infoPanelPortraitSize = XmlAttr.d(el, 'portraitSize', c.infoPanelPortraitSize);
    c.infoPanelPortraitRadius = XmlAttr.d(el, 'portraitRadius', c.infoPanelPortraitRadius);
    c.infoPanelNameFontSize = XmlAttr.d(el, 'nameFontSize', c.infoPanelNameFontSize);
    c.infoPanelLevelBadgePaddingH = XmlAttr.d(el, 'levelBadgePaddingH', c.infoPanelLevelBadgePaddingH);
    c.infoPanelLevelBadgePaddingV = XmlAttr.d(el, 'levelBadgePaddingV', c.infoPanelLevelBadgePaddingV);
    c.infoPanelLevelBadgeRadius = XmlAttr.d(el, 'levelBadgeRadius', c.infoPanelLevelBadgeRadius);
    c.infoPanelLevelBadgeFontSize = XmlAttr.d(el, 'levelBadgeFontSize', c.infoPanelLevelBadgeFontSize);
    c.infoPanelLabelFontSize = XmlAttr.d(el, 'labelFontSize', c.infoPanelLabelFontSize);
    c.infoPanelValueFontSize = XmlAttr.d(el, 'valueFontSize', c.infoPanelValueFontSize);
    c.infoPanelAttrIconSize = XmlAttr.d(el, 'attrIconSize', c.infoPanelAttrIconSize);
    c.infoPanelRowHeight = XmlAttr.d(el, 'rowHeight', c.infoPanelRowHeight);
    c.infoPanelRowSpacing = XmlAttr.d(el, 'rowSpacing', c.infoPanelRowSpacing);
  }

  static void _applyColors(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.colorAccent = XmlAttr.colorInt(el, 'accent', c.colorAccent);
    c.colorTitle = XmlAttr.colorInt(el, 'title', c.colorTitle);
    c.colorLabel = XmlAttr.colorInt(el, 'label', c.colorLabel);
    c.colorDanger = XmlAttr.colorInt(el, 'danger', c.colorDanger);
    c.colorCardName = XmlAttr.colorInt(el, 'cardName', c.colorCardName);
    c.colorCardLevel = XmlAttr.colorInt(el, 'cardLevel', c.colorCardLevel);
  }

  static void _applyOverlays(CharSelectUiConfig c, XmlElement? el) {
    if (el == null) return;
    c.enterBtnHoverOverlay = XmlAttr.color(el, 'enterBtnHover', c.enterBtnHoverOverlay);
    c.enterBtnPressedOverlay = XmlAttr.color(el, 'enterBtnPressed', c.enterBtnPressedOverlay);
    c.createBtnHoverOverlay = XmlAttr.color(el, 'createBtnHover', c.createBtnHoverOverlay);
    c.createBtnPressedOverlay = XmlAttr.color(el, 'createBtnPressed', c.createBtnPressedOverlay);
    c.deleteBtnHoverOverlay = XmlAttr.color(el, 'deleteBtnHover', c.deleteBtnHoverOverlay);
    c.deleteBtnPressedOverlay = XmlAttr.color(el, 'deleteBtnPressed', c.deleteBtnPressedOverlay);
    c.backBtnHoverOverlay = XmlAttr.color(el, 'backBtnHover', c.backBtnHoverOverlay);
    c.backBtnPressedOverlay = XmlAttr.color(el, 'backBtnPressed', c.backBtnPressedOverlay);
    c.cardHoverOverlay = XmlAttr.color(el, 'cardHover', c.cardHoverOverlay);
    c.cardPressedOverlay = XmlAttr.color(el, 'cardPressed', c.cardPressedOverlay);
  }
}
