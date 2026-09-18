/// 攻擊動畫的呈現方式。
enum AttackAnimType {
  /// 直接命中（近身攻擊、瞬發法術）：只在目標身上播 hitGfx。
  direct,

  /// 飛行道具（弓箭、飛劍、火球）：flyGfx 由施放者飛向目標，抵達後播 hitGfx。
  projectile;

  /// 由伺服器代號轉列舉；未知代號一律視為 [direct]。
  static AttackAnimType fromCode(int code) =>
      code == 1 ? AttackAnimType.projectile : AttackAnimType.direct;
}

/// 攻擊演出：只負責演出與傷害數字。
///
/// 攻擊者與目標一律以 objId 識別，玩家、NPC、怪物都適用。
/// 三個動畫編號皆可為 0 表示不播該段。
///
/// 血量不在本封包內 —— 血條由 [SHpUpdate] 獨立更新（血量會因治療、
/// 自然回復等非攻擊原因改變）；目標死亡則由 S_OBJECT_REMOVE 表達。
class SAttack {
  const SAttack({
    required this.attackerObjId,
    required this.targetObjId,
    required this.damage,
    required this.animType,
    required this.castGfx,
    required this.flyGfx,
    required this.hitGfx,
    this.hit = true,
  });

  final int attackerObjId;
  final int targetObjId;
  final int damage;

  final AttackAnimType animType;

  /// 施放者身上的動畫編號（0=無）。
  final int castGfx;

  /// 飛行中的動畫編號（僅 [AttackAnimType.projectile] 使用，0=無）。
  final int flyGfx;

  /// 命中時目標身上的動畫編號（0=無）。
  final int hitGfx;

  /// 是否命中。未命中時 [damage] 為 0，且目標血量不變。
  ///
  /// 不用「damage == 0」判斷 —— 傷害有下限 1，但將來若加入「完全格擋」，
  /// 0 傷害與未命中就不是同一回事了。
  final bool hit;

  factory SAttack.fromData(Map<String, dynamic> data) => SAttack(
        attackerObjId: (data['attackerObjId'] as num?)?.toInt() ?? 0,
        targetObjId: (data['targetObjId'] as num?)?.toInt() ?? 0,
        damage: (data['damage'] as num?)?.toInt() ?? 0,
        animType:
            AttackAnimType.fromCode((data['animType'] as num?)?.toInt() ?? 0),
        castGfx: (data['castGfx'] as num?)?.toInt() ?? 0,
        flyGfx: (data['flyGfx'] as num?)?.toInt() ?? 0,
        hitGfx: (data['hitGfx'] as num?)?.toInt() ?? 0,
        // 舊版伺服器沒有這個欄位，缺少時視為命中
        hit: data['hit'] as bool? ?? true,
      );
}
