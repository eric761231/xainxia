import 'package:flutter/material.dart';

import '../network/packets/server/s_party.dart';

/// 隊伍成員（UI 用的形式）。
///
/// 由伺服器的 `S_PARTY` 轉換而來。做成具名型別而非直接用封包的
/// [PartyMemberData]，是因為 UI 還需要「是不是隊長」「是不是自己」這兩個
/// 判斷 —— 它們來自封包的 `leaderObjId` 與本機的角色 objId，
/// 不是成員資料本身的欄位。
@immutable
class PartyMember {
  const PartyMember({
    required this.objId,
    required this.name,
    required this.level,
    required this.hp,
    required this.maxHp,
    required this.mp,
    required this.maxMp,
    required this.icon,
    this.isLeader = false,
    this.isSelf = false,
  });

  final int objId;
  final String name;
  final int level;
  final int hp;
  final int maxHp;
  final int mp;
  final int maxMp;

  /// 職業圖示。伺服器還沒有職業資料，暫時全部用同一個。
  final IconData icon;

  final bool isLeader;
  final bool isSelf;

  double get hpFraction => maxHp <= 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);
  double get mpFraction => maxMp <= 0 ? 0 : (mp / maxMp).clamp(0.0, 1.0);

  /// 由封包轉成 UI 用的成員。
  ///
  /// [selfObjId] 用來標出自己那一列 —— 自己那列不該出現「驅逐」。
  factory PartyMember.fromPacket(
    PartyMemberData d, {
    required int leaderObjId,
    required int selfObjId,
  }) =>
      PartyMember(
        objId: d.objId,
        name: d.name,
        level: d.level,
        hp: d.hp,
        maxHp: d.hpMax,
        mp: d.mp,
        maxMp: d.mpMax,
        icon: Icons.person,
        isLeader: d.objId == leaderObjId,
        isSelf: d.objId == selfObjId,
      );
}
