/// 地圖物件分類（對應伺服器 NpcType，DB npc.type_name）。
enum ObjectType {
  /// 可攻擊的怪物
  monster,

  /// 可交談的 NPC
  npc,

  /// 可交談並買賣的商店 NPC
  shop,

  /// 可互動採集的資源（植物／礦物）
  gather,

  /// 純裝飾場景物件，不可互動
  scenery;

  /// 由封包的 int 還原；未知值一律當作 [scenery]（最保守，不開放互動）。
  static ObjectType fromCode(int code) =>
      (code >= 0 && code < ObjectType.values.length)
          ? ObjectType.values[code]
          : ObjectType.scenery;
}

/// 地圖上的一個物件（NPC／怪物／採集點／場景物件）。
class MapObject {
  const MapObject({
    required this.objId,
    required this.npcId,
    required this.name,
    required this.type,
    required this.gfxid,
    required this.x,
    required this.y,
    required this.heading,
    required this.maxHp,
    required this.currentHp,
    required this.attackable,
    required this.talkable,
    required this.shop,
    required this.gatherable,
  });

  /// 世界唯一物件序號（互動封包以此指定目標）。
  final int objId;

  /// npc 模板編號。
  final int npcId;
  final String name;
  final ObjectType type;

  /// 外型編號。
  final int gfxid;
  final int x;
  final int y;

  /// 面向 0..7（0=NE,1=E,2=SE,3=S,4=SW,5=W,6=NW,7=N）。
  final int heading;
  final int maxHp;
  final int currentHp;

  /// 以下四項由伺服器依 [type] 推導，前端不需重複判斷分類規則。
  final bool attackable;
  final bool talkable;
  final bool shop;
  final bool gatherable;

  /// 是否可做任何互動（可點擊）。
  bool get interactive => type != ObjectType.scenery;

  factory MapObject.fromJson(Map<String, dynamic> j) => MapObject(
        objId: (j['objId'] as num?)?.toInt() ?? 0,
        npcId: (j['npcId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        type: ObjectType.fromCode((j['type'] as num?)?.toInt() ?? 4),
        gfxid: (j['gfxid'] as num?)?.toInt() ?? 0,
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        heading: (j['heading'] as num?)?.toInt() ?? 2,
        maxHp: (j['maxHp'] as num?)?.toInt() ?? 0,
        currentHp: (j['currentHp'] as num?)?.toInt() ?? 0,
        attackable: j['attackable'] as bool? ?? false,
        talkable: j['talkable'] as bool? ?? false,
        shop: j['shop'] as bool? ?? false,
        gatherable: j['gatherable'] as bool? ?? false,
      );
}

/// 地圖物件清單（回應 C_OBJECT_LIST，或進圖／換圖後由伺服器主動推送）。
class SObjectList {
  const SObjectList({required this.mapId, required this.objects});

  final int mapId;
  final List<MapObject> objects;

  factory SObjectList.fromData(Map<String, dynamic> data) => SObjectList(
        mapId: (data['mapId'] as num?)?.toInt() ?? 0,
        objects: (data['objects'] as List<dynamic>? ?? const [])
            .map((o) => MapObject.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}
