class SDeleteCharResult {
  const SDeleteCharResult({
    required this.success,
    required this.reason,
    required this.message,
  });

  final bool success;
  final String reason;
  final String message;

  factory SDeleteCharResult.fromData(Map<String, dynamic> data) {
    return SDeleteCharResult(
      success: data['success'] as bool? ?? false,
      reason: data['reason'] as String? ?? '',
      message: data['message'] as String? ?? '',
    );
  }
}
