/// 戰鬥結果封包（回應 C_USE_SKILL）。
///
/// 描述一次技能施放的結果：造成的傷害、目標剩餘血量、是否擊殺。
class SCombatResult {
  const SCombatResult({
    required this.casterId,
    required this.targetId,
    required this.skillId,
    required this.damage,
    required this.targetHp,
    required this.targetMaxHp,
    required this.killed,
    required this.message,
  });

  final int casterId;
  final int targetId;
  final int skillId;
  final int damage;
  final int targetHp;
  final int targetMaxHp;
  final bool killed;
  final String message;

  factory SCombatResult.fromData(Map<String, dynamic> data) => SCombatResult(
        casterId: data['casterId'] as int? ?? 0,
        targetId: data['targetId'] as int? ?? 0,
        skillId: data['skillId'] as int? ?? 0,
        damage: data['damage'] as int? ?? 0,
        targetHp: data['targetHp'] as int? ?? 0,
        targetMaxHp: data['targetMaxHp'] as int? ?? 0,
        killed: data['killed'] as bool? ?? false,
        message: data['message'] as String? ?? '',
      );
}
