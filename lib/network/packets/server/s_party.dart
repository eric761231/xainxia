/// 隊伍中的一名成員。
class PartyMemberData {
  const PartyMemberData({
    required this.objId,
    required this.name,
    required this.level,
    required this.hp,
    required this.hpMax,
    required this.mp,
    required this.mpMax,
  });

  final int objId;
  final String name;
  final int level;
  final int hp;
  final int hpMax;
  final int mp;
  final int mpMax;

  factory PartyMemberData.fromJson(Map<String, dynamic> j) => PartyMemberData(
        objId: (j['objId'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        level: (j['level'] as num?)?.toInt() ?? 1,
        hp: (j['hp'] as num?)?.toInt() ?? 0,
        hpMax: (j['hpMax'] as num?)?.toInt() ?? 0,
        mp: (j['mp'] as num?)?.toInt() ?? 0,
        mpMax: (j['mpMax'] as num?)?.toInt() ?? 0,
      );
}

/// 隊伍狀態。任何變動伺服器都整包重送，所以前端直接換掉整份，不做增量。
///
/// **成員為空代表已離隊或解散** —— 前端據此清空隊伍欄。
class SParty {
  const SParty({
    required this.partyId,
    required this.leaderObjId,
    required this.members,
  });

  final int partyId;
  final int leaderObjId;
  final List<PartyMemberData> members;

  bool get isEmpty => members.isEmpty;

  factory SParty.fromData(Map<String, dynamic> data) => SParty(
        partyId: (data['partyId'] as num?)?.toInt() ?? 0,
        leaderObjId: (data['leaderObjId'] as num?)?.toInt() ?? 0,
        members: [
          for (final m in (data['members'] as List<dynamic>? ?? const []))
            PartyMemberData.fromJson(m as Map<String, dynamic>),
        ],
      );
}

/// 收到組隊邀請。前端應跳出可接受／拒絕的提示。
class SPartyInvite {
  const SPartyInvite({required this.inviterObjId, required this.inviterName});

  final int inviterObjId;
  final String inviterName;

  factory SPartyInvite.fromData(Map<String, dynamic> data) => SPartyInvite(
        inviterObjId: (data['inviterObjId'] as num?)?.toInt() ?? 0,
        inviterName: data['inviterName'] as String? ?? '',
      );
}
