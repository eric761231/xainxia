class SLogoutResult {
  const SLogoutResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory SLogoutResult.fromData(Map<String, dynamic> data) {
    return SLogoutResult(
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? '',
    );
  }
}
