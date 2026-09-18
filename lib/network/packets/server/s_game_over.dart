/// 挑戰結算。玩家在秘境中死亡時送出。
///
/// 收到這包時角色**已經**被伺服器送回洞府了 —— 這包只是「剛才那一輪的成績」，
/// 不需要前端再送任何東西。玩家按「再挑戰」才會送 [CChallenge.enter]。
class SGameOver {
  const SGameOver({
    required this.wave,
    required this.kills,
    required this.seconds,
  });

  /// 撐到第幾波。
  final int wave;

  /// 擊殺數。
  final int kills;

  /// 存活秒數。
  final int seconds;

  /// 存活時間的顯示字串（`3:07`）。
  String get survivedText {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  factory SGameOver.fromData(Map<String, dynamic> data) => SGameOver(
        wave: (data['wave'] as num?)?.toInt() ?? 0,
        kills: (data['kills'] as num?)?.toInt() ?? 0,
        seconds: (data['seconds'] as num?)?.toInt() ?? 0,
      );
}
