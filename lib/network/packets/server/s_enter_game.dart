class SEnterGame {
  const SEnterGame({
    required this.objId,
    required this.charName,
    required this.mapId,
    required this.x,
    required this.y,
  });

  final int objId;
  final String charName;
  final int mapId;
  final int x;
  final int y;

  factory SEnterGame.fromData(Map<String, dynamic> data) {
    return SEnterGame(
      objId: data['objId'] as int? ?? 0,
      charName: data['charName'] as String? ?? '',
      mapId: data['mapId'] as int? ?? 0,
      x: data['x'] as int? ?? 0,
      y: data['y'] as int? ?? 0,
    );
  }
}
