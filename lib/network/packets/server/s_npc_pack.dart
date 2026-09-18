/// NPC 物件分類（對應伺服器 NpcType 的 int 代號）。
enum NpcObjectType {
  /// 可攻擊的怪物（不會出現在本封包，由 S_MONSTER_PACK 推送）
  monster,

  /// 可交談的 NPC
  npc,

  /// 可交談並買賣的商店 NPC
  shop,

  /// 可互動採集的資源物件（植物／礦物）
  gather,

  /// 純裝飾場景物件，不可互動
  scenery;

  /// 由伺服器代號轉列舉；未知代號一律視為 [scenery]（最保守，不可互動）。
  static NpcObjectType fromCode(int code) {
    switch (code) {
      case 0:
        return NpcObjectType.monster;
      case 1:
        return NpcObjectType.npc;
      case 2:
        return NpcObjectType.shop;
      case 3:
        return NpcObjectType.gather;
      default:
        return NpcObjectType.scenery;
    }
  }
}

/// 單一 NPC 物件。
///
/// 刻意不叫 MapObject —— 本地地圖模型 [../../game/map/iso_map_data.dart] 已有同名類別。
class NpcObject {
  const NpcObject({
    required this.objId,
    required this.name,
    required this.x,
    required this.y,
    required this.heading,
    required this.npcId,
    required this.gfxid,
    required this.type,
  });

  /// 世界唯一物件編號（移動／移除封包都以此對應）。
  final int objId;
  final String name;
  final int x;
  final int y;
  final int heading;

  /// npc 表的模板編號（同一種 NPC 會有多個 objId 共用同一個 npcId）。
  final int npcId;
  final int gfxid;
  final NpcObjectType type;

  /// 是否可互動（純裝飾場景物件除外）。
  bool get interactive => type != NpcObjectType.scenery;

  NpcObject copyWith({int? x, int? y, int? heading}) => NpcObject(
        objId: objId,
        name: name,
        x: x ?? this.x,
        y: y ?? this.y,
        heading: heading ?? this.heading,
        npcId: npcId,
        gfxid: gfxid,
        type: type,
      );

  factory NpcObject.fromJson(Map<String, dynamic> j) => NpcObject(
        objId: (j['objId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        heading: (j['heading'] as num?)?.toInt() ?? 2,
        npcId: (j['npcId'] as num?)?.toInt() ?? 0,
        gfxid: (j['gfxid'] as num?)?.toInt() ?? 0,
        type: NpcObjectType.fromCode((j['type'] as num?)?.toInt() ?? 4),
      );
}

/// 地圖上的 NPC 清單（不含怪物，怪物見 S_MONSTER_PACK）。
class SNpcPack {
  const SNpcPack({required this.mapId, required this.npcs});

  final int mapId;
  final List<NpcObject> npcs;

  factory SNpcPack.fromData(Map<String, dynamic> data) {
    final raw = data['npcs'] as List<dynamic>? ?? const [];
    return SNpcPack(
      mapId: (data['mapId'] as num?)?.toInt() ?? 0,
      npcs: raw
          .map((n) => NpcObject.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }
}
