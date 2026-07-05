class SCreateCharResult {
  const SCreateCharResult({
    required this.success,
    required this.reason,
    required this.message,
  });

  final bool success;
  final String reason;
  final String message;

  factory SCreateCharResult.fromData(Map<String, dynamic> data) {
    return SCreateCharResult(
      success: data['success'] as bool? ?? false,
      reason: data['reason'] as String? ?? '',
      message: data['message'] as String? ?? '',
    );
  }
}
