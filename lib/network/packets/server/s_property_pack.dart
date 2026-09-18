/// 單一場景物件（來自伺服器 property 表）。
///
/// [bubbleText] 不隨本封包預載 —— 互動時才由 S_BUBBLE_DIALOG 單獨送出。
class PropertyObject {
  const PropertyObject({
    required this.objId,
    required this.name,
    required this.x,
    required this.y,
    required this.heading,
    required this.propertyId,
    required this.pngid,
    required this.blocking,
    required this.footprintW,
    required this.footprintH,
    required this.offsetX,
    required this.offsetY,
    required this.action,
    required this.actionType,
    required this.value,
  });

  /// 世界唯一物件編號（狀態更新／移除封包都以此對應）。
  final int objId;
  final String name;
  final int x;
  final int y;
  final int heading;

  /// property 表的模板編號。
  final int propertyId;

  /// 圖片編號，對應 assets/data/object_catalog.json 的物件 id。
  final int pngid;

  /// 是否阻擋通行（伺服器權威）。
  final bool blocking;

  /// 碰撞佔格寬（地面格數，非視覺尺寸）。
  /// 視覺大小由 object_catalog 的圖與 tilesW 決定，兩者不可混用。
  final int footprintW;

  /// 碰撞佔格高（地面格數，非視覺尺寸）。
  final int footprintH;

  /// 像素微調（玩家家具用；壁掛物以負的 offsetY 往上推到牆面高度）。
  final int offsetX;
  final int offsetY;

  /// 是否可互動（採空後伺服器會改為 false）。
  final bool action;

  /// 互動方式：1=對話、2=採集；0=不可互動。
  final int actionType;

  /// 進度條之類的數值。
  final int value;

  PropertyObject copyWith({int? value, bool? action}) => PropertyObject(
        objId: objId,
        name: name,
        x: x,
        y: y,
        heading: heading,
        propertyId: propertyId,
        pngid: pngid,
        blocking: blocking,
        footprintW: footprintW,
        footprintH: footprintH,
        offsetX: offsetX,
        offsetY: offsetY,
        action: action ?? this.action,
        actionType: actionType,
        value: value ?? this.value,
      );

  factory PropertyObject.fromJson(Map<String, dynamic> j) => PropertyObject(
        objId: (j['objId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        heading: (j['heading'] as num?)?.toInt() ?? 2,
        propertyId: (j['propertyId'] as num?)?.toInt() ?? 0,
        pngid: (j['pngid'] as num?)?.toInt() ?? 0,
        blocking: j['blocking'] as bool? ?? false,
        footprintW: (j['footprintW'] as num?)?.toInt() ?? 1,
        footprintH: (j['footprintH'] as num?)?.toInt() ?? 1,
        offsetX: (j['offsetX'] as num?)?.toInt() ?? 0,
        offsetY: (j['offsetY'] as num?)?.toInt() ?? 0,
        action: j['action'] as bool? ?? false,
        actionType: (j['actionType'] as num?)?.toInt() ?? 0,
        value: (j['value'] as num?)?.toInt() ?? 0,
      );
}

/// 地圖上的場景物件清單。
class SPropertyPack {
  const SPropertyPack({required this.mapId, required this.properties});

  final int mapId;
  final List<PropertyObject> properties;

  factory SPropertyPack.fromData(Map<String, dynamic> data) {
    final raw = data['properties'] as List<dynamic>? ?? const [];
    return SPropertyPack(
      mapId: (data['mapId'] as num?)?.toInt() ?? 0,
      properties: raw
          .map((p) => PropertyObject.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
