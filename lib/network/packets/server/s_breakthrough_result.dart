class SBreakthroughResult {
  const SBreakthroughResult({
    required this.success,
    required this.reason,
    required this.message,
    required this.realm,
    required this.realmStage,
    required this.realmLevel,
    required this.hp,
    required this.hpMax,
    required this.mp,
    required this.mpMax,
    required this.defense,
    required this.attack,
    required this.hit,
    required this.dodge,
    required this.hpRegen,
    required this.mpRegen,
    required this.puppetMax,
    required this.spellLearnRate,
    required this.craftProficiencyRate,
  });

  final bool success;
  final String reason;
  final String message;

  /// 以下欄位只有在 success 為 true 時才有意義
  final String realm;
  final int realmStage;
  final int realmLevel;
  final int hp;
  final int hpMax;
  final int mp;
  final int mpMax;
  final int defense;
  final int attack;
  final int hit;
  final int dodge;
  final int hpRegen;
  final int mpRegen;
  final int puppetMax;
  final int spellLearnRate;
  final int craftProficiencyRate;

  factory SBreakthroughResult.fromData(Map<String, dynamic> data) {
    return SBreakthroughResult(
      success: data['success'] as bool? ?? false,
      reason: data['reason'] as String? ?? '',
      message: data['message'] as String? ?? '',
      realm: data['realm'] as String? ?? '',
      realmStage: data['realmStage'] as int? ?? 0,
      realmLevel: data['realmLevel'] as int? ?? 0,
      hp: data['hp'] as int? ?? 0,
      hpMax: data['hpMax'] as int? ?? 0,
      mp: data['mp'] as int? ?? 0,
      mpMax: data['mpMax'] as int? ?? 0,
      defense: data['defense'] as int? ?? 0,
      attack: data['attack'] as int? ?? 0,
      hit: data['hit'] as int? ?? 0,
      dodge: data['dodge'] as int? ?? 0,
      hpRegen: data['hpRegen'] as int? ?? 0,
      mpRegen: data['mpRegen'] as int? ?? 0,
      puppetMax: data['puppetMax'] as int? ?? 0,
      spellLearnRate: data['spellLearnRate'] as int? ?? 100,
      craftProficiencyRate: data['craftProficiencyRate'] as int? ?? 100,
    );
  }
}
