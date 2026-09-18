/// 採集結果封包（回應 C_GATHER，只送給採集者本人）。
///
/// success=false 時以 [message] 說明原因（太遠／已枯竭／背包滿）。
/// success=true 時帶入獲得的道具與此節點的再生秒數。
///
/// 與 SPropertyUpdate 的分工：本封包是給採集者的私人結果，
/// 世界上該物件的狀態變化則由 S_PROPERTY_UPDATE 廣播給全場。
class SGatherResult {
  const SGatherResult({
    required this.success,
    required this.objId,
    required this.itemId,
    required this.itemName,
    required this.amount,
    required this.message,
    required this.respawnMs,
  });

  final bool success;

  /// 被採集的場景物件編號。
  final int objId;
  final int itemId;
  final String itemName;
  final int amount;
  final String message;
  final int respawnMs;

  factory SGatherResult.fromData(Map<String, dynamic> data) => SGatherResult(
        success: data['success'] as bool? ?? false,
        objId: (data['objId'] as num?)?.toInt() ?? 0,
        itemId: (data['itemId'] as num?)?.toInt() ?? 0,
        itemName: data['itemName'] as String? ?? '',
        amount: (data['amount'] as num?)?.toInt() ?? 0,
        message: data['message'] as String? ?? '',
        respawnMs: (data['respawnMs'] as num?)?.toInt() ?? 0,
      );
}
