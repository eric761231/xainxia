/// 通用物件移除。
///
/// 任何世界物件從地圖上消失時推送：藥草被採光、礦石被挖盡、
/// 怪物死亡、NPC 下線。前端依 [objId] 移除畫面上的對應物件。
class SObjectRemove {
  const SObjectRemove({required this.objId});

  final int objId;

  factory SObjectRemove.fromData(Map<String, dynamic> data) => SObjectRemove(
        objId: (data['objId'] as num?)?.toInt() ?? 0,
      );
}
