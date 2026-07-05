class SSystemMessage {
  const SSystemMessage({required this.message});

  final String message;

  factory SSystemMessage.fromData(Map<String, dynamic> data) {
    return SSystemMessage(message: data['message'] as String? ?? '');
  }
}
