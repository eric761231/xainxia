import '../../opcodes/client_opcodes.dart';

/// 使用技能封包（攻擊目標）。
///
/// 觸發流程：可攻擊目標距離滿足 → 客戶端彈出技能選單 →
/// 玩家選定技能後才送出此封包。伺服器應回 [S_COMBAT_RESULT]。
class CUseSkill {
  CUseSkill._();

  static Map<String, dynamic> build({
    required int skillId,
    required int targetId,
    required int x,
    required int y,
  }) =>
      {
        'op': ClientOpcodes.cUseSkill,
        'data': {'skillId': skillId, 'targetId': targetId, 'x': x, 'y': y},
      };
}
