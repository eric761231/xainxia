/// 境界內降級結果。
class SLevelDownResult {
  const SLevelDownResult({
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

  factory SLevelDownResult.fromData(Map<String, dynamic> data) {
    return SLevelDownResult(
      success: data['success'] as bool? ?? false,
      reason: data['reason'] as String? ?? '',
      message: data['message'] as String? ?? '',
      realmLevel: (data['realmLevel'] as num?)?.toInt() ?? 1,
      exp: (data['exp'] as num?)?.toInt() ?? 0,
      expMax: (data['expMax'] as num?)?.toInt() ?? 0,
    );
  }
}
