/// 換圖／傳送結果：伺服器權威的到達地圖、座標與面向。
/// facing 0-7：NE/E/SE/S/SW/W/NW/N（畫面方向順時針）。
class SMapChange {
  const SMapChange({
    required this.mapId,
    required this.x,
    required this.y,
    required this.facing,
  });

  final int mapId;
  final int x;
  final int y;
  final int facing;

  factory SMapChange.fromData(Map<String, dynamic> data) {
    return SMapChange(
      mapId: (data['mapId'] as num?)?.toInt() ?? 0,
      x: (data['x'] as num?)?.toInt() ?? 0,
      y: (data['y'] as num?)?.toInt() ?? 0,
      facing: (data['facing'] as num?)?.toInt() ?? 2,
    );
  }
}
