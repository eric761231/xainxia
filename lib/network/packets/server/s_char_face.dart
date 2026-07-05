/// 伺服器廣播的人物轉向封包。
/// facing 0-7：NE/E/SE/S/SW/W/NW/N（畫面方向順時針）。
class SCharFace {
  const SCharFace({
    required this.charName,
    required this.facing,
  });

  final String charName;
  final int facing;

  factory SCharFace.fromData(Map<String, dynamic> data) => SCharFace(
        charName: data['charName'] as String? ?? '',
        facing: data['facing'] as int? ?? 0,
      );
}
