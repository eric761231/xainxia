import '../network/packets/server/s_breakthrough_result.dart';
import '../network/packets/server/s_char_stats_update.dart';
import '../network/packets/server/s_character_amount.dart';
import '../network/packets/server/s_character_list.dart';

class GameCharacter {
  const GameCharacter({
    required this.objId,
    required this.name,
    required this.level,
    required this.sex,
    required this.attribute,
    required this.realm,
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
    required this.puppetMax,
    required this.spellLearnRate,
    required this.craftProficiencyRate,
    required this.statsIntel,
    required this.statsConstitution,
    required this.statsAgility,
    required this.statsSpirit,
    required this.natalWeapon,
    required this.coreTechnique,
    required this.faction,
    required this.lifeJob,
    required this.lifeJobLevel,
    this.realmStage = 0,
    this.hpRegen = 0,
    this.mpRegen = 0,
  });

  final int objId;
  final String name;
  final int level;
  final int sex;

  /// 靈根：0=金 … 7=幻
  final int attribute;

  /// 境界名稱（如「鍛體期」）
  final String realm;

  final int exp;
  final int expMax;

  final int hp;
  final int hpMax;

  final int mp;
  final int mpMax;

  /// 防禦力
  final int defense;

  final int attack;
  final int hit;
  final int dodge;
  final int puppetMax;
  final int spellLearnRate;
  final int craftProficiencyRate;

  /// 悟性（stats_intel）
  final int statsIntel;

  /// 體魄（stats_constitution）
  final int statsConstitution;

  /// 敏捷（stats_agility）
  final int statsAgility;

  /// 神識（stats_spirit）
  final int statsSpirit;

  /// 本命武器名稱（空字串表示未裝備）
  final String natalWeapon;

  /// 核心功法名稱（空字串表示未習得）
  final String coreTechnique;

  /// 所屬勢力（如「凌雲宗」）
  final String faction;

  /// 生活職業（如「煉丹師」）
  final String lifeJob;

  /// 生活職業等級
  final int lifeJobLevel;

  /// 境界小階段（遊戲中即時更新；選角列表預設 0）
  final int realmStage;

  /// 生命回復（遊戲中即時；選角列表預設 0）
  final int hpRegen;

  /// 法力回復（遊戲中即時；選角列表預設 0）
  final int mpRegen;

  double get expFraction => expMax > 0 ? (exp / expMax).clamp(0.0, 1.0) : 0.0;
  double get hpFraction => hpMax > 0 ? (hp / hpMax).clamp(0.0, 1.0) : 0.0;
  double get mpFraction => mpMax > 0 ? (mp / mpMax).clamp(0.0, 1.0) : 0.0;

  factory GameCharacter.fromMap(Map<String, dynamic> map) {
    return GameCharacter(
      objId: map['objId'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      level: map['level'] as int? ?? 1,
      sex: map['sex'] as int? ?? 0,
      attribute: map['attribute'] as int? ?? 0,
      realm: map['realm'] as String? ?? '',
      exp: map['exp'] as int? ?? 0,
      expMax: map['expMax'] as int? ?? 0,
      hp: map['hp'] as int? ?? 0,
      hpMax: map['hpMax'] as int? ?? 0,
      mp: map['mp'] as int? ?? 0,
      mpMax: map['mpMax'] as int? ?? 0,
      defense: map['defense'] as int? ?? 0,
      attack: map['attack'] as int? ?? 0,
      hit: map['hit'] as int? ?? 0,
      dodge: map['dodge'] as int? ?? 0,
      puppetMax: map['puppetMax'] as int? ?? 0,
      spellLearnRate: map['spellLearnRate'] as int? ?? 100,
      craftProficiencyRate: map['craftProficiencyRate'] as int? ?? 100,
      statsIntel: map['statsIntel'] as int? ?? 0,
      statsConstitution: map['statsConstitution'] as int? ?? 0,
      statsAgility: map['statsAgility'] as int? ?? 0,
      statsSpirit: map['statsSpirit'] as int? ?? 0,
      natalWeapon: map['natalWeapon'] as String? ?? '',
      coreTechnique: map['coreTechnique'] as String? ?? '',
      faction: map['faction'] as String? ?? '',
      lifeJob: map['lifeJob'] as String? ?? '',
      lifeJobLevel: map['lifeJobLevel'] as int? ?? 0,
      realmStage: map['realmStage'] as int? ?? 0,
      hpRegen: map['hpRegen'] as int? ?? 0,
      mpRegen: map['mpRegen'] as int? ?? 0,
    );
  }

  GameCharacter copyWith({
    String? realm,
    int? level,
    int? realmStage,
    int? exp,
    int? expMax,
    int? hp,
    int? hpMax,
    int? mp,
    int? mpMax,
    int? defense,
    int? attack,
    int? hit,
    int? dodge,
    int? hpRegen,
    int? mpRegen,
    int? puppetMax,
    int? spellLearnRate,
    int? craftProficiencyRate,
    int? statsIntel,
    int? statsSpirit,
    int? statsAgility,
    int? statsConstitution,
  }) {
    return GameCharacter(
      objId: objId,
      name: name,
      level: level ?? this.level,
      sex: sex,
      attribute: attribute,
      realm: realm ?? this.realm,
      exp: exp ?? this.exp,
      expMax: expMax ?? this.expMax,
      hp: hp ?? this.hp,
      hpMax: hpMax ?? this.hpMax,
      mp: mp ?? this.mp,
      mpMax: mpMax ?? this.mpMax,
      defense: defense ?? this.defense,
      attack: attack ?? this.attack,
      hit: hit ?? this.hit,
      dodge: dodge ?? this.dodge,
      puppetMax: puppetMax ?? this.puppetMax,
      spellLearnRate: spellLearnRate ?? this.spellLearnRate,
      craftProficiencyRate: craftProficiencyRate ?? this.craftProficiencyRate,
      statsIntel: statsIntel ?? this.statsIntel,
      statsConstitution: statsConstitution ?? this.statsConstitution,
      statsAgility: statsAgility ?? this.statsAgility,
      statsSpirit: statsSpirit ?? this.statsSpirit,
      natalWeapon: natalWeapon,
      coreTechnique: coreTechnique,
      faction: faction,
      lifeJob: lifeJob,
      lifeJobLevel: lifeJobLevel,
      realmStage: realmStage ?? this.realmStage,
      hpRegen: hpRegen ?? this.hpRegen,
      mpRegen: mpRegen ?? this.mpRegen,
    );
  }

  /// 由 S_CHAR_STATS_UPDATE 合併即時素質（保留身分欄位，避免顯示不同步）。
  GameCharacter applyStatsUpdate(SCharStatsUpdate u) {
    return copyWith(
      realm: u.realm,
      realmStage: u.realmStage,
      level: u.realmLevel,
      exp: u.exp,
      expMax: u.expMax,
      hp: u.hp,
      hpMax: u.hpMax,
      mp: u.mp,
      mpMax: u.mpMax,
      defense: u.defense,
      attack: u.attack,
      hit: u.hit,
      dodge: u.dodge,
      hpRegen: u.hpRegen,
      mpRegen: u.mpRegen,
      puppetMax: u.puppetMax,
      spellLearnRate: u.spellLearnRate,
      craftProficiencyRate: u.craftProficiencyRate,
      statsIntel: u.statsIntel,
      statsSpirit: u.statsSpirit,
      statsAgility: u.statsAgility,
      statsConstitution: u.statsConstitution,
    );
  }

  /// 由突破結果合併（保留身分與素質點）。
  GameCharacter mergeBreakthrough(SBreakthroughResult r) {
    return copyWith(
      realm: r.realm,
      realmStage: r.realmStage,
      level: r.realmLevel,
      hp: r.hp,
      hpMax: r.hpMax,
      mp: r.mp,
      mpMax: r.mpMax,
      defense: r.defense,
      attack: r.attack,
      hit: r.hit,
      dodge: r.dodge,
      hpRegen: r.hpRegen,
      mpRegen: r.mpRegen,
      puppetMax: r.puppetMax,
      spellLearnRate: r.spellLearnRate,
      craftProficiencyRate: r.craftProficiencyRate,
    );
  }
}

class CharacterListSummary {
  const CharacterListSummary({
    required this.characters,
    required this.count,
    required this.maxSlots,
  });

  final List<GameCharacter> characters;
  final int count;
  final int maxSlots;

  bool get canCreateMore => count < maxSlots;

  factory CharacterListSummary.fromPackets(
    SCharacterAmount amount,
    SCharacterList list,
  ) {
    return CharacterListSummary(
      characters: list.characters.map(GameCharacter.fromMap).toList(),
      count: amount.count,
      maxSlots: amount.maxSlots,
    );
  }

  static CharacterListSummary empty({int maxSlots = 2}) {
    return CharacterListSummary(
      characters: const [],
      count: 0,
      maxSlots: maxSlots,
    );
  }
}
