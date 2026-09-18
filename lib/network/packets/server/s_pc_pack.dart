/// 同一張地圖上的玩家（含收件者自己）。
///
/// 伺服器對每張地圖只算一次名單，所以**自己也在裡面**，由前端濾掉。
///
/// 這一包是「整份名單」而不是增量的新增／移除 —— 只要地圖上的人有變動
/// 就整包重送。同圖人數是個位數，這樣可以整類消滅「畫面留下鬼影」的問題。
class SPcPack {
  const SPcPack({required this.mapId, required this.players});

  final int mapId;
  final List<RemotePlayerData> players;

  factory SPcPack.fromData(Map<String, dynamic> data) => SPcPack(
        mapId: (data['mapId'] as num?)?.toInt() ?? 0,
        players: ((data['players'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RemotePlayerData.fromJson)
            .toList(growable: false),
      );
}

/// 名單裡的一個人。
class RemotePlayerData {
  const RemotePlayerData({
    required this.objId,
    required this.name,
    required this.x,
    required this.y,
    required this.heading,
    required this.sex,
    required this.level,
  });

  final int objId;
  final String name;
  final int x;
  final int y;
  final int heading;

  /// 0=男 1=女。外觀目前只由這個決定。
  final int sex;
  final int level;

  factory RemotePlayerData.fromJson(Map<String, dynamic> j) => RemotePlayerData(
        objId: (j['objId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        x: (j['x'] as num?)?.toInt() ?? 0,
        y: (j['y'] as num?)?.toInt() ?? 0,
        heading: (j['heading'] as num?)?.toInt() ?? 2,
        sex: (j['sex'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
      );
}
