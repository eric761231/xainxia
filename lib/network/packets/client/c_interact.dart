import '../../opcodes/client_opcodes.dart';

/// 互動／對話請求封包（NPC、可調查物件）。
///
/// 前置條件：客戶端已把角色走到目標相鄰一格才送出。
/// 伺服器應回 [S_DIALOG]（對話內容與選項）。
class CInteract {
  CInteract._();

  static Map<String, dynamic> build({
    required int npcId,
    required int x,
    required int y,
  }) =>
      {
        'op': ClientOpcodes.cInteract,
        'data': {'npcId': npcId, 'x': x, 'y': y},
      };
}
