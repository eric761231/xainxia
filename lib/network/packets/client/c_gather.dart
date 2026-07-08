import '../../opcodes/client_opcodes.dart';

/// 採集請求封包（藥草／礦石等資源節點）。
///
/// 前置條件：客戶端已把角色走到資源節點相鄰一格才送出。
/// 伺服器應回 [S_GATHER_RESULT]（成功掉落／失敗原因／再生時間）。
class CGather {
  CGather._();

  static Map<String, dynamic> build({
    required int x,
    required int y,
    required String resourceId,
  }) =>
      {
        'op': ClientOpcodes.cGather,
        'data': {'x': x, 'y': y, 'resourceId': resourceId},
      };
}
