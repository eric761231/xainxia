import 'package:flame/components.dart';

/// 地圖投影：等距（2:1 菱形）或俯視（正方格）。
///
/// **用明確的欄位，不要靠格尺寸推。** 「tileWidth == tileHeight 就是俯視」
/// 看起來很聰明，但之後只要有人把等距地圖的格改成正方（例如做 1:1 等距），
/// 投影就會意外切換，而且沒有任何地方會報錯。
enum MapProjection { iso, topDown }

/// 座標工具（tile ↔ screen）。
///
/// 兩種投影都回**格的上緣中點**：等距是菱形頂點、俯視是方格上邊中點。
/// 這樣呼叫端貼圖的那一行完全不用改 —— 它本來就是把圖貼進
/// `Rect.fromLTWH(x - halfW, y, halfW * 2, halfH * 2)`，
/// 也就是「以上緣中點為基準的外接矩形」，兩種投影都成立。
///
///     等距    screenX = (tx - ty) * halfW      screenY = (tx + ty) * halfH
///     俯視    screenX = tx * 2 * halfW + halfW  screenY = ty * 2 * halfH
class IsoCoord {
  const IsoCoord(this.x, this.y);

  final int x;
  final int y;

  /// Tile → screen（格的上緣中點）。
  static Vector2 tileToScreen(int tx, int ty, double halfW, double halfH,
          {MapProjection projection = MapProjection.iso}) =>
      switch (projection) {
        MapProjection.iso =>
          Vector2((tx - ty) * halfW, (tx + ty) * halfH),
        MapProjection.topDown =>
          Vector2(tx * 2 * halfW + halfW, ty * 2 * halfH),
      };

  /// Screen → tile。
  ///
  /// 用 floor 而不是 round：格內任何一點都要映到同一格，
  /// 用 round 的話靠近邊界的點會跳到隔壁。
  static (int tx, int ty) screenToTile(
      Vector2 pos, double halfW, double halfH,
      {MapProjection projection = MapProjection.iso}) {
    switch (projection) {
      case MapProjection.iso:
        final tx = ((pos.x / halfW + pos.y / halfH) / 2).floor();
        final ty = ((pos.y / halfH - pos.x / halfW) / 2).floor();
        return (tx, ty);
      case MapProjection.topDown:
        return ((pos.x / (halfW * 2)).floor(), (pos.y / (halfH * 2)).floor());
    }
  }

  /// 一格的四個角（順時針，從上緣中點起算）。
  ///
  /// 等距是菱形、俯視是方格。畫格線、點擊高亮、footprint 陰影都用這個 ——
  /// **形狀只能有一個來源**，散在各處各畫一份的話換投影就會漏改。
  static List<Vector2> cellCorners(double topX, double topY,
      double halfW, double halfH,
      {MapProjection projection = MapProjection.iso}) {
    switch (projection) {
      case MapProjection.iso:
        return [
          Vector2(topX, topY),
          Vector2(topX + halfW, topY + halfH),
          Vector2(topX, topY + halfH * 2),
          Vector2(topX - halfW, topY + halfH),
        ];
      case MapProjection.topDown:
        return [
          Vector2(topX - halfW, topY),
          Vector2(topX + halfW, topY),
          Vector2(topX + halfW, topY + halfH * 2),
          Vector2(topX - halfW, topY + halfH * 2),
        ];
    }
  }
}
