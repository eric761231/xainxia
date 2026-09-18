/// 地圖清單中的單一地圖。
class MapListEntry {
  const MapListEntry({required this.mapId, required this.name});

  final int mapId;
  final String name;

  factory MapListEntry.fromJson(Map<String, dynamic> j) => MapListEntry(
        mapId: (j['mapId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
      );
}

/// 地圖清單（GM 指令 `.maps` 的回應）。
///
/// 供 GM 面板畫出可傳送的地圖列表。伺服器送結構化資料而非文字，
/// 讓前端不必解析清單字串（地圖名稱一改就會壞）。
class SMapList {
  const SMapList({required this.maps});

  final List<MapListEntry> maps;

  factory SMapList.fromData(Map<String, dynamic> data) {
    final raw = data['maps'] as List<dynamic>? ?? const [];
    return SMapList(
      maps: raw
          .map((m) => MapListEntry.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
