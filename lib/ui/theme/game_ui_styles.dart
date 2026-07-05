import 'package:flutter/material.dart';

import 'game_ui_fonts.dart';

/// -----------------------------------------------------------------------
/// GameUiStyles — 全域共用 UI 樣式工具類別
///
/// 類比 Java：這就像是一個 final class 裡面全是 static 方法的「工具類 (Utility Class)」，
/// 例如 Java 的 Collections、Arrays，專門提供靜態方法給其他類別使用。
///
/// 用法：直接呼叫靜態方法，不需要 new 出物件實例：
///   style: GameUiStyles.shadowTextStyle(fontSize: 16)
///   style: GameUiStyles.capsuleButtonStyle()
/// -----------------------------------------------------------------------
abstract final class GameUiStyles {
  // 私有建構子：防止被 new 出來（純工具類不需要實例）
  // abstract final class 在 Dart 3 中已自帶此效果，無需手動私有建構子

  /// 帶有黑色外框陰影的白色文字樣式
  ///
  /// 用途：背景圖複雜時（白雲、亮色背景），白字容易消失，
  ///        透過雙重陰影在白字外圍包一層黑邊，確保任何背景都清晰可讀。
  ///
  /// 參數：
  ///   [fontSize]   字型大小，預設 16
  ///   [fontWeight] 字型粗細，預設 normal
  static TextStyle shadowTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: GameUiFonts.kingHwaOldSong,
      shadows: [
        // 右下陰影
        Shadow(
          blurRadius: 3.0,
          color: Colors.black.withValues(alpha: 0.85),
          offset: const Offset(1.0, 1.0),
        ),
        // 左上陰影（形成黑色外框感）
        Shadow(
          blurRadius: 3.0,
          color: Colors.black.withValues(alpha: 0.85),
          offset: const Offset(-1.0, -1.0),
        ),
      ],
    );
  }

  /// 半透明膠囊按鈕樣式
  ///
  /// 用途：全遊戲 UI 統一使用同一套按鈕外觀，
  ///       包含帳號畫面、伺服器選單、未來其他彈窗。
  ///
  /// 參數：
  ///   [alpha] 按鈕背景透明度，預設 0.10（10% 微弱透明白）
  static ButtonStyle capsuleButtonStyle({double alpha = 0.10}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: alpha),
      elevation: 0,                         // 扁平化，無陰影
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28), // 膠囊圓角
      ),
    );
  }
}
