import 'package:flutter/material.dart';

import '../ui_xaml_assets.dart';
import '../ui_xaml_loader.dart';
import '../ui_xaml_node.dart';
import '../ui_xaml_parts.dart';
import '../ui_xaml_registry.dart';
import '../ui_xaml_spec_holder.dart';

/// 伺服器格線的外觀。
@immutable
class ServerGridSpec {
  const ServerGridSpec({
    required this.box,
    required this.columns,
    required this.itemHeight,
    required this.rowGap,
    required this.colGap,
    required this.nameSize,
    required this.statusSize,
    required this.countSize,
    required this.nameColor,
    required this.countColor,
    required this.selectedLineColor,
    required this.selectedLineWidth,
    required this.selectedGlowColor,
    required this.selectedGlowBlur,
    required this.selectedGlowOpacity,
    required this.disabledOpacity,
  });

  final XamlBox box;
  final int columns;
  final double itemHeight;
  final double rowGap;
  final double colGap;
  final double nameSize;
  final double statusSize;
  final double countSize;
  final Color nameColor;
  final Color countColor;

  /// 選中效果：淡青底線 + 微光。刻意不提供「填滿底色」的選項 —— 填滿會讓未選中
  /// 的項目看起來像被停用，而停用是留給維護／離線表達的。
  final Color selectedLineColor;
  final double selectedLineWidth;
  final Color selectedGlowColor;
  final double selectedGlowBlur;
  final double selectedGlowOpacity;

  /// 不可選（維護／離線）項目的整體透明度。
  final double disabledOpacity;

  static ServerGridSpec from(UiXamlNode? node, ServerGridSpec fallback) {
    if (node == null) return fallback;
    return ServerGridSpec(
      box: XamlBox.from(node, fallback.box),
      columns: node.i('columns', fallback.columns, min: 1, max: 6),
      itemHeight: node.d('itemHeight', fallback.itemHeight, min: 24, max: 240),
      rowGap: node.d('rowGap', fallback.rowGap, min: 0, max: 120),
      colGap: node.d('colGap', fallback.colGap, min: 0, max: 120),
      nameSize: node.d('nameSize', fallback.nameSize, min: 6, max: 72),
      statusSize: node.d('statusSize', fallback.statusSize, min: 6, max: 72),
      countSize: node.d('countSize', fallback.countSize, min: 6, max: 72),
      nameColor: node.color('nameColor', fallback.nameColor),
      countColor: node.color('countColor', fallback.countColor),
      selectedLineColor:
          node.color('selectedLineColor', fallback.selectedLineColor),
      selectedLineWidth: node.d('selectedLineWidth', fallback.selectedLineWidth,
          min: 0.5, max: 8),
      selectedGlowColor:
          node.color('selectedGlowColor', fallback.selectedGlowColor),
      selectedGlowBlur:
          node.d('selectedGlowBlur', fallback.selectedGlowBlur, min: 0, max: 48),
      selectedGlowOpacity: node
          .d('selectedGlowOpacity', fallback.selectedGlowOpacity, min: 0, max: 1),
      disabledOpacity:
          node.d('disabledOpacity', fallback.disabledOpacity, min: 0.1, max: 1),
    );
  }
}

/// 伺服器選單的顯示規格（設計稿像素，1920×1080）。
@immutable
class ServerSelectUiSpec {
  const ServerSelectUiSpec({
    this.panel = const XamlInkFade(
      box: XamlBox(centerX: 960, centerY: 470, width: 760, height: 520),
      color: Color(0xFF0E0F12),
      centerOpacity: 0,
      fadeX: 120,
      fadeY: 100,
    ),
    this.title = const XamlText(
      text: '選擇伺服器',
      centerX: 960,
      centerY: 250,
      size: 34,
      color: Color(0xFFF2EADA),
    ),
    this.refreshing = const XamlText(
      text: '更新中…',
      centerX: 960,
      centerY: 300,
      size: 14,
      color: Color(0xFFA8A093),
    ),
    this.grid = const ServerGridSpec(
      box: XamlBox(centerX: 960, centerY: 440, width: 660, height: 280),
      columns: 1,
      itemHeight: 44,
      rowGap: 2,
      colGap: 16,
      nameSize: 18,
      statusSize: 14,
      countSize: 14,
      nameColor: Color(0xFFF2EADA),
      countColor: Color(0xFFA8A093),
      selectedLineColor: Color(0xFF74D2D5),
      selectedLineWidth: 2,
      selectedGlowColor: Color(0xFF74D2D5),
      selectedGlowBlur: 10,
      selectedGlowOpacity: 0,
      disabledOpacity: 0.45,
    ),
    this.cancel = const XamlButton(
      box: XamlBox(centerX: 840, centerY: 660, width: 180, height: 48),
      text: '取消',
      textSize: 18,
      textColor: Color(0xFFA8A093),
    ),
    this.confirm = const XamlButton(
      box: XamlBox(centerX: 1080, centerY: 660, width: 180, height: 48),
      text: '確認',
      textSize: 18,
      textColor: Color(0xFFE8C86A),
    ),
  });

  final XamlInkFade panel;
  final XamlText title;
  final XamlText refreshing;
  final ServerGridSpec grid;
  final XamlButton cancel;
  final XamlButton confirm;

  static const ServerSelectUiSpec defaults = ServerSelectUiSpec();

  static final holder = UiXamlSpecHolder<ServerSelectUiSpec>(
    view: UiXamlRegistry.serverSelect,
    initial: defaults,
    build: _build,
  );

  static ServerSelectUiSpec get current => holder.value;

  static ServerSelectUiSpec _build(UiXamlResult result, UiXamlAssets assets) {
    final document = result.document;
    if (document == null) return defaults;
    const d = defaults;
    return ServerSelectUiSpec(
      panel: XamlInkFade.from(document.findById('panel'), d.panel),
      title: XamlText.from(document.findById('title'), d.title),
      refreshing: XamlText.from(document.findById('refreshing'), d.refreshing),
      grid: ServerGridSpec.from(document.findById('grid'), d.grid),
      cancel: XamlButton.from(document.findById('cancel'), d.cancel),
      confirm: XamlButton.from(document.findById('confirm'), d.confirm),
    );
  }

  @visibleForTesting
  static ServerSelectUiSpec fromResultForTest(
          UiXamlResult result, UiXamlAssets assets) =>
      _build(result, assets);
}
