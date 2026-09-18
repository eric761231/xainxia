import '../../opcodes/client_opcodes.dart';

/// 秘境挑戰的進出。
///
/// 死亡造成的退出**不需要**送這包 —— 伺服器自己會結算並把角色送回洞府。
class CChallenge {
  CChallenge._();

  static Map<String, dynamic> _build(String action) => {
        'op': ClientOpcodes.cChallenge,
        'data': {'action': action},
      };

  /// 進入秘境（進場一律回滿血，由伺服器處理）。
  static Map<String, dynamic> enter() => _build('enter');

  /// 還沒死就主動退出。
  static Map<String, dynamic> leave() => _build('leave');
}
