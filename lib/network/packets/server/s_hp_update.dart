/// 血量更新：任何物件的血條變動都走這一包。
///
/// 被攻擊扣血、治療、自然回復、怪物初次現身皆適用，依 [objId] 對應物件。
/// 刻意與 [SAttack] 分離 —— 攻擊只負責演出與傷害數字，血量是獨立的狀態，
/// 會因為非攻擊原因而改變。物件死亡不靠本封包表達，改送 S_OBJECT_REMOVE。
class SHpUpdate {
  const SHpUpdate({
    required this.objId,
    required this.currentHp,
    required this.maxHp,
  });

  final int objId;
  final int currentHp;
  final int maxHp;

  factory SHpUpdate.fromData(Map<String, dynamic> data) => SHpUpdate(
        objId: (data['objId'] as num?)?.toInt() ?? 0,
        currentHp: (data['currentHp'] as num?)?.toInt() ?? 0,
        maxHp: (data['maxHp'] as num?)?.toInt() ?? 0,
      );
}
