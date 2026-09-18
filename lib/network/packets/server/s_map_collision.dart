/// 地圖的地形碰撞格（牆／水／懸崖）。
///
/// 進圖時搭在 S_MAP_INFO 的 `blocked` 欄位一起送，GM 即時編輯後則以本封包廣播。
/// 兩者格式相同，故解析集中在 [parseBlocked] 一處。
class SMapCollision {
  const SMapCollision({required this.mapId, required this.blocked});

  final int mapId;

  /// 不可通行的格子，元素為 (地圖座標 x, y)。
  final List<(int, int)> blocked;

  factory SMapCollision.fromData(Map<String, dynamic> data) => SMapCollision(
        mapId: (data['mapId'] as num?)?.toInt() ?? 0,
        blocked: parseBlocked(data['blocked']),
      );

  /// 解析 `[[x,y],[x,y],...]`；格式不符的元素直接略過而非拋例外 ——
  /// 一格壞掉不該讓整張地圖的碰撞都收不到。
  static List<(int, int)> parseBlocked(dynamic raw) {
    if (raw is! List) return const [];
    final out = <(int, int)>[];
    for (final e in raw) {
      if (e is List && e.length >= 2) {
        final x = (e[0] as num?)?.toInt();
        final y = (e[1] as num?)?.toInt();
        if (x != null && y != null) out.add((x, y));
      }
    }
    return out;
  }
}
