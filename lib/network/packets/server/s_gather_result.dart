/// 採集結果封包（回應 C_GATHER）。
///
/// success=false 時以 [message] 說明原因（太遠／已枯竭／背包滿）。
/// success=true 時帶入獲得的道具與此節點的再生秒數。
class SGatherResult {
  const SGatherResult({
    required this.success,
    required this.resourceId,
    required this.x,
    required this.y,
    required this.itemId,
    required this.itemName,
    required this.amount,
    required this.message,
    required this.respawnMs,
  });

  final bool success;
  final String resourceId;
  final int x;
  final int y;
  final int itemId;
  final String itemName;
  final int amount;
  final String message;
  final int respawnMs;

  factory SGatherResult.fromData(Map<String, dynamic> data) => SGatherResult(
        success: data['success'] as bool? ?? false,
        resourceId: data['resourceId'] as String? ?? '',
        x: data['x'] as int? ?? 0,
        y: data['y'] as int? ?? 0,
        itemId: data['itemId'] as int? ?? 0,
        itemName: data['itemName'] as String? ?? '',
        amount: data['amount'] as int? ?? 0,
        message: data['message'] as String? ?? '',
        respawnMs: data['respawnMs'] as int? ?? 0,
      );
}
