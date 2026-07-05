class SCharStatsUpdate {
  const SCharStatsUpdate({
    required this.realm,
    required this.realmStage,
    required this.realmLevel,
    required this.exp,
    required this.expMax,
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
    required this.statsIntel,
    required this.statsSpirit,
    required this.statsAgility,
    required this.statsConstitution,
  });

  final String realm;
  final int realmStage;
  final int realmLevel;
  final int exp;
  final int expMax;
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
  final int statsIntel;
  final int statsSpirit;
  final int statsAgility;
  final int statsConstitution;

  factory SCharStatsUpdate.fromData(Map<String, dynamic> data) {
    return SCharStatsUpdate(
      realm: data['realm'] as String? ?? '',
      realmStage: data['realmStage'] as int? ?? 0,
      realmLevel: data['realmLevel'] as int? ?? 1,
      exp: data['exp'] as int? ?? 0,
      expMax: data['expMax'] as int? ?? 0,
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
      statsIntel: data['statsIntel'] as int? ?? 0,
      statsSpirit: data['statsSpirit'] as int? ?? 0,
      statsAgility: data['statsAgility'] as int? ?? 0,
      statsConstitution: data['statsConstitution'] as int? ?? 0,
    );
  }
}
