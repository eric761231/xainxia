import '../network/packets/server/s_breakthrough_result.dart';
import '../network/packets/server/s_char_stats_update.dart';
import 'character_summary.dart';

/// 遊戲中即時角色屬性（由 S_CHAR_STATS_UPDATE / 突破結果等更新）。
class PlayerLiveStats {
  const PlayerLiveStats({
    required this.charName,
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

  final String charName;
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

  double get expFraction => expMax > 0 ? (exp / expMax).clamp(0.0, 1.0) : 0.0;
  double get hpFraction => hpMax > 0 ? (hp / hpMax).clamp(0.0, 1.0) : 0.0;
  double get mpFraction => mpMax > 0 ? (mp / mpMax).clamp(0.0, 1.0) : 0.0;

  factory PlayerLiveStats.fromGameCharacter(GameCharacter character) {
    return PlayerLiveStats(
      charName: character.name,
      realm: character.realm,
      realmStage: 0,
      realmLevel: character.level,
      exp: character.exp,
      expMax: character.expMax,
      hp: character.hp,
      hpMax: character.hpMax,
      mp: character.mp,
      mpMax: character.mpMax,
      defense: character.defense,
      attack: character.attack,
      hit: character.hit,
      dodge: character.dodge,
      hpRegen: 0,
      mpRegen: 0,
      puppetMax: character.puppetMax,
      spellLearnRate: character.spellLearnRate,
      craftProficiencyRate: character.craftProficiencyRate,
      statsIntel: character.statsIntel,
      statsSpirit: character.statsSpirit,
      statsAgility: character.statsAgility,
      statsConstitution: character.statsConstitution,
    );
  }

  factory PlayerLiveStats.fromCharStatsUpdate(
    SCharStatsUpdate update, {
    required String charName,
  }) {
    return PlayerLiveStats(
      charName: charName,
      realm: update.realm,
      realmStage: update.realmStage,
      realmLevel: update.realmLevel,
      exp: update.exp,
      expMax: update.expMax,
      hp: update.hp,
      hpMax: update.hpMax,
      mp: update.mp,
      mpMax: update.mpMax,
      defense: update.defense,
      attack: update.attack,
      hit: update.hit,
      dodge: update.dodge,
      hpRegen: update.hpRegen,
      mpRegen: update.mpRegen,
      puppetMax: update.puppetMax,
      spellLearnRate: update.spellLearnRate,
      craftProficiencyRate: update.craftProficiencyRate,
      statsIntel: update.statsIntel,
      statsSpirit: update.statsSpirit,
      statsAgility: update.statsAgility,
      statsConstitution: update.statsConstitution,
    );
  }

  PlayerLiveStats mergeBreakthrough(SBreakthroughResult result) {
    return copyWith(
      realm: result.realm,
      realmStage: result.realmStage,
      realmLevel: result.realmLevel,
      hp: result.hp,
      hpMax: result.hpMax,
      mp: result.mp,
      mpMax: result.mpMax,
      defense: result.defense,
      attack: result.attack,
      hit: result.hit,
      dodge: result.dodge,
      hpRegen: result.hpRegen,
      mpRegen: result.mpRegen,
      puppetMax: result.puppetMax,
      spellLearnRate: result.spellLearnRate,
      craftProficiencyRate: result.craftProficiencyRate,
    );
  }

  PlayerLiveStats copyWith({
    String? realm,
    int? realmStage,
    int? realmLevel,
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
  }) {
    return PlayerLiveStats(
      charName: charName,
      realm: realm ?? this.realm,
      realmStage: realmStage ?? this.realmStage,
      realmLevel: realmLevel ?? this.realmLevel,
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
      hpRegen: hpRegen ?? this.hpRegen,
      mpRegen: mpRegen ?? this.mpRegen,
      puppetMax: puppetMax ?? this.puppetMax,
      spellLearnRate: spellLearnRate ?? this.spellLearnRate,
      craftProficiencyRate:
          craftProficiencyRate ?? this.craftProficiencyRate,
      statsIntel: statsIntel,
      statsSpirit: statsSpirit,
      statsAgility: statsAgility,
      statsConstitution: statsConstitution,
    );
  }
}
