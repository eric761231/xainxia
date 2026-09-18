import 's_map_collision.dart';

/// 地圖上的傳送點（小地圖藍色光點 + 觸發偵測）。
class PortalPoint {
  const PortalPoint({
    required this.portalId,
    required this.locX,
    required this.locY,
    required this.triggerRange,
    required this.name,
  });

  final int portalId;
  final int locX;
  final int locY;

  /// 觸發範圍（格數，Chebyshev 距離 ≤ 此值可觸發）；0=精準踏格。
  final int triggerRange;
  final String name;

  factory PortalPoint.fromJson(Map<String, dynamic> j) => PortalPoint(
        portalId: (j['portalId'] as num?)?.toInt() ?? 0,
        locX: (j['locX'] as num?)?.toInt() ?? 0,
        locY: (j['locY'] as num?)?.toInt() ?? 0,
        triggerRange: (j['triggerRange'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
      );

  /// 玩家格 (x,y) 是否在此傳送點觸發範圍內（Chebyshev 距離）。
  bool inRange(int x, int y) =>
      (x - locX).abs() <= triggerRange && (y - locY).abs() <= triggerRange;
}

/// 地圖資訊：地名、尺寸（格）與傳送點清單。供小地圖顯示與 portal 觸發偵測。
class SMapInfo {
  const SMapInfo({
    required this.mapId,
    required this.mapName,
    required this.gfxid,
    required this.width,
    required this.height,
    required this.portals,
    required this.blocked,
  });

  final int mapId;
  final String mapName;

  /// 場景底圖編號，對應 assets/data/object_catalog.json 的物件 id（0=無底圖）。
  final int gfxid;
  final int width;
  final int height;
  final List<PortalPoint> portals;

  /// 地形不可通行的格子（地圖座標）。與 S_MAP_COLLISION 同格式，
  /// 搭進圖那一包一起送，省一次往返。
  final List<(int, int)> blocked;

  factory SMapInfo.fromData(Map<String, dynamic> data) {
    final rawPortals = data['portals'] as List<dynamic>? ?? const [];
    return SMapInfo(
      mapId: (data['mapId'] as num?)?.toInt() ?? 0,
      mapName: data['mapName'] as String? ?? '',
      gfxid: (data['gfxid'] as num?)?.toInt() ?? 0,
      width: (data['width'] as num?)?.toInt() ?? 0,
      height: (data['height'] as num?)?.toInt() ?? 0,
      portals: rawPortals
          .map((p) => PortalPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      blocked: SMapCollision.parseBlocked(data['blocked']),
    );
  }
}
