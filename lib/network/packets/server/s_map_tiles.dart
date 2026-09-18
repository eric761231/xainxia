/// 地圖圖磚：哪個座標鋪哪一張圖。
///
/// 進圖時由伺服器送來。在此之前這份資料是前端資產（`assets/maps/0.json`），
/// 但那份 JSON 同時存了地圖邊界，與伺服器 `map` 表的 `min_x/max_x` 重複 ——
/// 伺服器改了邊界前端不會跟著變，座標空間就錯開，而且不拋例外，
/// 只表現成「人物站的位置怪怪的」。現在資料只有伺服器一份。
///
/// **前後端的統一代號是圖磚編號**，配合 [tiles] 對照表使用。編號本身沒有意義，
/// 要看它對到哪個檔名 —— 重新切圖、換掉某一張，只要改對照表，
/// 地圖資料一格都不用動。
///
/// [ground] 的座標**就是遊戲格座標**，中間沒有 coordOffset 這種容易對錯的東西。
class SMapTiles {
  const SMapTiles({
    required this.mapId,
    required this.tileWidth,
    required this.tileHeight,
    required this.walkMin,
    required this.walkMax,
    required this.tileDir,
    required this.tiles,
    required this.ground,
  });

  final int mapId;
  final int tileWidth;
  final int tileHeight;

  /// 可走區的格座標範圍。
  final int walkMin;
  final int walkMax;

  /// 圖磚檔的子資料夾（相對 `assets/tiles/`）。
  final String tileDir;

  /// 圖磚編號 → 檔名。
  final Map<int, String> tiles;

  /// 每一格的鋪法：`(遊戲座標 x, 遊戲座標 y, 圖磚編號)`。沒列到的格子不鋪。
  final List<(int, int, int)> ground;

  bool get isValid => ground.isNotEmpty && tiles.isNotEmpty;

  /// 某編號的圖磚檔路徑（相對 `assets/tiles/`）；查無回 null。
  String? pathFor(int tileId) {
    final name = tiles[tileId];
    if (name == null || name.isEmpty) return null;
    return tileDir.isEmpty ? name : '$tileDir/$name';
  }

  factory SMapTiles.fromData(Map<String, dynamic> data) {
    final rawTiles = data['tiles'] as Map<String, dynamic>? ?? const {};
    final tiles = <int, String>{};
    for (final e in rawTiles.entries) {
      final id = int.tryParse(e.key);
      if (id != null) tiles[id] = e.value as String? ?? '';
    }

    final ground = <(int, int, int)>[];
    for (final cell in (data['ground'] as List<dynamic>? ?? const [])) {
      // 每一格是 [x, y, 圖磚編號]；格式不對的略過而非整包丟掉 ——
      // 一格壞掉不該讓整張地圖的地面都不見
      if (cell is! List || cell.length < 3) continue;
      final x = (cell[0] as num?)?.toInt();
      final y = (cell[1] as num?)?.toInt();
      final id = (cell[2] as num?)?.toInt();
      if (x != null && y != null && id != null) ground.add((x, y, id));
    }

    return SMapTiles(
      mapId: (data['mapId'] as num?)?.toInt() ?? 0,
      tileWidth: (data['tileWidth'] as num?)?.toInt() ?? 64,
      tileHeight: (data['tileHeight'] as num?)?.toInt() ?? 32,
      walkMin: (data['walkMin'] as num?)?.toInt() ?? 0,
      walkMax: (data['walkMax'] as num?)?.toInt() ?? 0,
      tileDir: data['tileDir'] as String? ?? '',
      tiles: tiles,
      ground: ground,
    );
  }
}
