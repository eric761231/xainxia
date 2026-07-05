class SLevelUpResult {
  const SLevelUpResult({
    required this.success,
    required this.reason,
    required this.message,
    required this.realmLevel,
    required this.exp,
    required this.expMax,
  });

  final bool success;
  final String reason;
  final String message;
  final int realmLevel;
  final int exp;
  final int expMax;

  factory SLevelUpResult.fromData(Map<String, dynamic> data) {
    return SLevelUpResult(
      success: data['success'] as bool? ?? false,
      reason: data['reason'] as String? ?? '',
      message: data['message'] as String? ?? '',
      realmLevel: data['realmLevel'] as int? ?? 1,
      exp: data['exp'] as int? ?? 0,
      expMax: data['expMax'] as int? ?? 0,
    );
  }
}
