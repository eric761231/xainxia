/// GM 指令執行結果。
///
/// 只送給下指令的人。沒有這包的話，指令打錯字會完全沒反應，
/// 分辨不出是「指令錯」還是「功能壞掉」。
class SGmResult {
  const SGmResult({required this.success, required this.message});

  final bool success;

  /// 給玩家看的結果訊息；可能含換行（例如 .help 的指令一覽）。
  final String message;

  factory SGmResult.fromData(Map<String, dynamic> data) => SGmResult(
        success: data['success'] as bool? ?? false,
        message: data['message'] as String? ?? '',
      );
}
