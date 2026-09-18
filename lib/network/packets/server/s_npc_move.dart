/// NPC／怪物移動廣播。
///
/// 對應人物的 [SCharMove]；差別在於人物以 charName 識別，
/// 而 NPC／怪物一律以 [objId] 識別（名稱會重複，例如同張圖上多隻野狼）。
/// 怪物與 NPC 在伺服器同為 NpcInstance、移動欄位相同，因此共用同一包。
class SNpcMove {
  const SNpcMove({
    required this.objId,
    required this.x,
    required this.y,
    required this.heading,
  });

  final int objId;
  final int x;
  final int y;
  final int heading;

  factory SNpcMove.fromData(Map<String, dynamic> data) => SNpcMove(
        objId: (data['objId'] as num?)?.toInt() ?? 0,
        x: (data['x'] as num?)?.toInt() ?? 0,
        y: (data['y'] as num?)?.toInt() ?? 0,
        heading: (data['heading'] as num?)?.toInt() ?? 2,
      );
}
