import 'package:flame/components.dart';

/// 等距座標工具（tile ↔ screen）。
///
/// 座標定義：(screenX, screenY) 指菱形頂點。
/// - screenX = (tx - ty) * halfW
/// - screenY = (tx + ty) * halfH
class IsoCoord {
  const IsoCoord(this.x, this.y);

  final int x;
  final int y;

  /// Tile → screen（返回菱形頂點位置）。
  static Vector2 tileToScreen(int tx, int ty, double halfW, double halfH) =>
      Vector2((tx - ty) * halfW, (tx + ty) * halfH);

  /// Screen → tile（最近 tile）。
  /// Screen → tile（floor 確保點在菱形內的任何位置都映射到同一格）。
  static (int tx, int ty) screenToTile(
      Vector2 pos, double halfW, double halfH) {
    final tx = ((pos.x / halfW + pos.y / halfH) / 2).floor();
    final ty = ((pos.y / halfH - pos.x / halfW) / 2).floor();
    return (tx, ty);
  }
}
