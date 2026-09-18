/// 法力更新：與 [SHpUpdate] 同形，但推送對象不同。
///
/// 血條是所有看得見的人都要更新，法力則只送給自己與隊友
/// —— 敵對目標不該知道你還剩多少魔。
/// 施法扣魔、喝藥回魔、自然回復、升級補滿皆走本封包。
class SMpUpdate {
  const SMpUpdate({
    required this.objId,
    required this.currentMp,
    required this.maxMp,
  });

  final int objId;
  final int currentMp;
  final int maxMp;

  factory SMpUpdate.fromData(Map<String, dynamic> data) => SMpUpdate(
        objId: (data['objId'] as num?)?.toInt() ?? 0,
        currentMp: (data['currentMp'] as num?)?.toInt() ?? 0,
        maxMp: (data['maxMp'] as num?)?.toInt() ?? 0,
      );
}
