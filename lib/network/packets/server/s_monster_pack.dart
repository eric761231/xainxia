/// 單一怪物物件。
///
/// 與 [NpcObject] 的差別：怪物一定可攻擊，因此帶血量欄位。
class MonsterObject {
  const MonsterObject({
    required this.objId,
    required this.name,
    required this.x,
    required this.y,
    required this.heading,
    required this.npcId,
    required this.gfxid,
    required this.maxHp,
    required this.currentHp,
  });

  /// 世界唯一物件編號（移動／移除封包都以此對應）。
  final int objId;
  final String name;
  final int x;
  final int y;
  final int heading;

  /// npc 表的模板編號。
  final int npcId;
  final int gfxid;
  final int maxHp;
  final int currentHp;

  MonsterObject copyWith({
    int? x,
    int? y,
    int? heading,
    int? currentHp,
  }) =>
      MonsterObject(
        objId: objId,
        name: name,
        x: x ?? this.x,
        y: y ?? this.y,
        heading: heading ?? this.heading,
        npcId: npcId,
        gfxid: gfxid,
        maxHp: maxHp,
        currentHp: currentHp ?? this.currentHp,
      );

  factory MonsterObject.fromJson(Map<String, dynamic> j) => MonsterObject(
        objId: (j['objId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        heading: (j['heading'] as num?)?.toInt() ?? 2,
        npcId: (j['npcId'] as num?)?.toInt() ?? 0,
        gfxid: (j['gfxid'] as num?)?.toInt() ?? 0,
        maxHp: (j['maxHp'] as num?)?.toInt() ?? 0,
        currentHp: (j['currentHp'] as num?)?.toInt() ?? 0,
      );
}

/// 地圖上的怪物清單。
class SMonsterPack {
  const SMonsterPack({required this.mapId, required this.monsters});

  final int mapId;
  final List<MonsterObject> monsters;

  factory SMonsterPack.fromData(Map<String, dynamic> data) {
    final raw = data['monsters'] as List<dynamic>? ?? const [];
    return SMonsterPack(
      mapId: (data['mapId'] as num?)?.toInt() ?? 0,
      monsters: raw
          .map((m) => MonsterObject.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
