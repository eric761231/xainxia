import 'package:flutter/material.dart';

import 'game_design.dart';

/// 遊戲內面板的共用色票與文字樣式。
///
/// 在此之前，`_gold`／`_goldBright`／`_panelBg`／`_ts()` 在
/// `game_hud_overlay.dart`、`gm_panel.dart`、`decor_panel.dart` 各複製一份，
/// 連 `_panelBg` 的透明度都已經分家（0xD9 vs 0xF2）。集中在這裡之後，
/// 調一次配色三個面板一起變。
///
/// 配色原則是**扁平化**：層次用填色的深淺表達，不用描邊。
/// 描邊只保留在真正需要強調的地方（等級菱形、經驗弧線、選中態）。
class PanelTheme {
  PanelTheme._();

  // ---- 主色 ----
  static const gold = GameDesign.gold;
  static const goldBright = GameDesign.gold;

  // ---- 面板 ----
  /// 面板底色。扁平化後不再靠邊框界定範圍，底色要夠實才撐得住。
  static const panelBg = GameDesign.ink;

  /// 面板外框：只留一絲輪廓，避免在深色背景上糊成一片。
  static const panelBorder = Colors.transparent;

  /// 分隔線。原本用 0x33C9A24B（金色 20%），在扁平化的版面裡太搶眼。
  static const divider = Color(0x14FFFFFF);

  // ---- 按鈕／格子 ----
  /// 一般按鈕底色（取代描邊）。
  static const cellBg = Color(0x14FFFFFF);

  /// 選中／啟用中的按鈕底色。
  static const cellBgActive = Color(0x443E8D85);

  /// 危險操作（驅逐、離開隊伍）。
  static const danger = GameDesign.danger;

  /// 次要資訊文字。
  static const textDim = GameDesign.muted;
  static const textFaint = Color(0xFFBED0CD);

  static const radius = 10.0;
  static const cellRadius = 6.0;

  /// 面板外觀：底色 + 幾乎不可見的輪廓 + 圓角。
  static BoxDecoration panelDeco({double r = radius}) => BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: panelBorder, width: 1),
      );

  /// 按鈕外觀：純填色，不描邊。
  static BoxDecoration cellDeco({bool active = false}) => BoxDecoration(
        color: active ? cellBgActive : cellBg,
        borderRadius: BorderRadius.circular(cellRadius),
      );

  /// 面板文字。一律帶陰影 —— 面板可能疊在明亮的場景上。
  static TextStyle ts({
    double size = 12,
    Color color = Colors.white,
    FontWeight? weight,
  }) =>
      GameDesign.text(size: size, color: color, weight: weight ?? FontWeight.normal);
}
