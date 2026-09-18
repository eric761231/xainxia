/// 波次狀態。伺服器每秒廣播一次。
///
/// 固定頻率推送而不是「只在變化時送」—— 內容只有三個整數，
/// 前端因此不必自己推算倒數，中途進來的玩家也立刻同步。
class SWave {
  const SWave({
    required this.wave,
    required this.alive,
    required this.breakLeft,
  });

  /// 目前第幾波；0 = 尚未開始。
  final int wave;

  /// 本波還活著的怪物數。
  final int alive;

  /// 距離下一波還有幾秒；> 0 代表這一波已清完，正在倒數。
  final int breakLeft;

  bool get isActive => wave > 0;
  bool get isResting => breakLeft > 0;

  factory SWave.fromData(Map<String, dynamic> data) => SWave(
        wave: (data['wave'] as num?)?.toInt() ?? 0,
        alive: (data['alive'] as num?)?.toInt() ?? 0,
        breakLeft: (data['breakLeft'] as num?)?.toInt() ?? 0,
      );
}
