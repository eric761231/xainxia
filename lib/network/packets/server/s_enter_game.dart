/// 角色進入世界。
///
/// 除了角色自己的資料，也帶上前端需要的**伺服器常數**（目前只有
/// [challengeMapId]）—— 前後端各寫一個常數的話，企劃改了 `wave_config`
/// 的地圖，前端的按鈕就會停在舊的那張圖上，而且不會有任何錯誤訊息。
class SEnterGame {
  const SEnterGame({
    required this.objId,
    required this.charName,
    required this.mapId,
    required this.x,
    required this.y,
    this.challengeMapId = -1,
  });

  final int objId;
  final String charName;
  final int mapId;
  final int x;
  final int y;

  /// 秘境挑戰地圖；-1 = 伺服器沒有啟用中的挑戰地圖。
  final int challengeMapId;

  factory SEnterGame.fromData(Map<String, dynamic> data) {
    return SEnterGame(
      objId: data['objId'] as int? ?? 0,
      charName: data['charName'] as String? ?? '',
      mapId: data['mapId'] as int? ?? 0,
      x: data['x'] as int? ?? 0,
      y: data['y'] as int? ?? 0,
      // 舊版伺服器沒有這個欄位；-1 讓「離開秘境」按鈕單純不顯示，
      // 而不是誤指到某一張真實存在的地圖
      challengeMapId: (data['challengeMapId'] as num?)?.toInt() ?? -1,
    );
  }
}
