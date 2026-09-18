import '../../opcodes/client_opcodes.dart';

/// 隊伍操作。一個封包承載所有動作，用 `action` 分派 ——
/// 與伺服器的 C_Party 對應。
class CParty {
  CParty._();

  static Map<String, dynamic> _build(String action, [String target = '']) => {
        'op': ClientOpcodes.cParty,
        'data': {'action': action, 'target': target},
      };

  /// 邀請某人組隊（以角色名指定）。
  static Map<String, dynamic> invite(String name) => _build('invite', name);

  static Map<String, dynamic> accept() => _build('accept');
  static Map<String, dynamic> decline() => _build('decline');
  static Map<String, dynamic> leave() => _build('leave');

  /// 驅逐隊員（只有隊長可用，伺服器會再驗一次）。
  static Map<String, dynamic> kick(String name) => _build('kick', name);

  /// 委任隊長。
  static Map<String, dynamic> promote(String name) => _build('promote', name);
}
