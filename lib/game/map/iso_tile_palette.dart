import 'dart:ui';

/// 地形 tile 的內建色塊調色盤（tileId 1~8 對應色）。
///
/// 缺 atlas 時的 fallback 顯示；同時供地圖編輯器調色盤使用，
/// 讓渲染與編輯器共用同一組顏色（見 iso_map_component / tools/map_editor）。
abstract final class IsoTilePalette {
  /// index i 對應 tileId (i+1)。
  static const List<Color> tileColors = [
    Color(0xFF3A8C3D), // 1 草地
    Color(0xFF8B8070), // 2 石板路
    Color(0xFF2B7DC4), // 3 水面
    Color(0xFF5A5050), // 4 邊界石
    Color(0xFF2D6A2F), // 5 深草地
    Color(0xFF8B6914), // 6 泥土
    Color(0xFF74C69D), // 7 淺草地
    Color(0xFF95B8D1), // 8 淺水
  ];

  /// tileId 對應顏色（超出範圍 clamp 到端點）。
  static Color colorFor(int tileId) {
    final idx = (tileId - 1).clamp(0, tileColors.length - 1);
    return tileColors[idx];
  }

  /// 可用的地形 tileId 清單（1..N）。
  static List<int> get tileIds =>
      List<int>.generate(tileColors.length, (i) => i + 1);
}
