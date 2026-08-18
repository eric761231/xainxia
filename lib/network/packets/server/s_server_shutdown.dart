/// 伺服器關閉通知（S_SERVER_SHUTDOWN）。收到後客戶端關閉遊戲視窗。
class SServerShutdown {
  const SServerShutdown({required this.message});

  final String message;

  factory SServerShutdown.fromData(Map<String, dynamic> data) =>
      SServerShutdown(message: data['message'] as String? ?? '');
}
