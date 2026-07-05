/// 伺服器廣播的人物移動封包。
/// facing 0-7：NE/E/SE/S/SW/W/NW/N（畫面方向順時針）。
class SCharMove {
  const SCharMove({
    required this.charName,
    required this.x,
    required this.y,
    required this.facing,
  });

  final String charName;
  final int x;
  final int y;
  final int facing;

  factory SCharMove.fromData(Map<String, dynamic> data) => SCharMove(
        charName: data['charName'] as String? ?? '',
        x: data['x'] as int? ?? 0,
        y: data['y'] as int? ?? 0,
        facing: data['facing'] as int? ?? 0,
      );
}
