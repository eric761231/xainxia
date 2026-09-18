/// 可放置家具的一個項目。
class PlaceableItem {
  const PlaceableItem({
    required this.propertyId,
    required this.pngid,
    required this.name,
    required this.placement,
    required this.blocking,
    required this.footprintW,
    required this.footprintH,
  });

  final int propertyId;

  /// 圖片編號，對應 object_catalog.json。
  final int pngid;
  final String name;

  /// 放置面：`floor` 需可走格、`wall` 需不可走格、`any` 不限。
  /// 前端據此決定預覽時哪些格子是合法的。
  final String placement;
  final bool blocking;
  final int footprintW;
  final int footprintH;

  bool get isFloor => placement == 'floor';
  bool get isWall => placement == 'wall';

  factory PlaceableItem.fromJson(Map<String, dynamic> j) => PlaceableItem(
        propertyId: (j['propertyId'] as num?)?.toInt() ?? 0,
        pngid: (j['pngid'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        placement: j['placement'] as String? ?? 'floor',
        blocking: j['blocking'] as bool? ?? false,
        footprintW: (j['footprintW'] as num?)?.toInt() ?? 1,
        footprintH: (j['footprintH'] as num?)?.toInt() ?? 1,
      );
}

/// 可放置家具清單（洞府布置面板用）。
///
/// 只含 `property.placeable = 1` 的項目 —— 樹木、礦石那類世界物件
/// 不會出現在玩家的布置清單裡。
class SPlaceableList {
  const SPlaceableList({required this.items});

  final List<PlaceableItem> items;

  factory SPlaceableList.fromData(Map<String, dynamic> data) {
    final raw = data['items'] as List<dynamic>? ?? const [];
    return SPlaceableList(
      items: raw
          .map((e) => PlaceableItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
