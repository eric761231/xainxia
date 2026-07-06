import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../network/packets/client/c_face.dart';
import '../network/packets/client/c_move.dart';
import '../network/packets/server/s_char_face.dart';
import '../network/packets/server/s_char_move.dart';
import '../network/packets/server/s_enter_game.dart';
import '../services/game_session_service.dart';
import 'map/iso_map_component.dart';

/// 世界場景：載入等距地圖並放置玩家出生點。
class WorldSceneComponent extends PositionComponent {
  WorldSceneComponent({
    required this.enterGame,
    this.sessionService,
    this.appearanceKey = 'male',
    this.onRequestMapChange,
  });

  final SEnterGame enterGame;
  final GameSessionService? sessionService;

  /// 踏到出口 → 請求切換地圖（本地）：(toMap, toX, toY)。
  final void Function(int toMap, int toX, int toY)? onRequestMapChange;

  /// 人物外觀鍵（依所選角色 sex 推導），往下傳給 IsoMapComponent。
  final String appearanceKey;

  IsoMapComponent? _map;
  final Map<String, ({int x, int y, int facing})> _remotePlayers = {};

  /// 其他玩家移動廣播（S_CHAR_MOVE）。
  void applyRemoteMove(SCharMove move) {
    _remotePlayers[move.charName] = (x: move.x, y: move.y, facing: move.facing);
    debugPrint(
        'Remote move: ${move.charName} -> (${move.x}, ${move.y}) facing=${move.facing}');
  }

  /// 其他玩家轉向廣播（S_CHAR_FACE）。
  void applyRemoteFace(SCharFace face) {
    final prev = _remotePlayers[face.charName];
    _remotePlayers[face.charName] = (
      x: prev?.x ?? enterGame.x,
      y: prev?.y ?? enterGame.y,
      facing: face.facing,
    );
    debugPrint('Remote face: ${face.charName} -> facing=${face.facing}');
  }

  Map<String, ({int x, int y, int facing})> get remotePlayers =>
      Map.unmodifiable(_remotePlayers);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.topLeft;
    position = Vector2.zero();

    if (size.x <= 0 || size.y <= 0) {
      final p = parent;
      size = (p is PositionComponent && p.size.x > 0)
          ? p.size
          : Vector2(1280, 720);
    }

    _map = IsoMapComponent(
      mapId: enterGame.mapId,
      spawnTileX: enterGame.x,
      spawnTileY: enterGame.y,
      appearanceKey: appearanceKey,
      onPlayerStep: _onPlayerStep,
      onPlayerFace: _onPlayerFace,
      onEnterExit: (exit) =>
          onRequestMapChange?.call(exit.toMap, exit.toX, exit.toY),
    );
    add(_map!);
  }

  void _onPlayerStep(int x, int y, int facing) {
    sessionService?.send(CMove.build(x: x, y: y, facing: facing));
  }

  void _onPlayerFace(int facing) {
    sessionService?.send(CFace.build(facing: facing));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (size.x <= 0 || size.y <= 0) return;
    final map = _map;
    if (map == null) return;
    final center = map.contentCenterLocal;
    if (center == null) return;
    // 整張地圖固定置中於畫面，不隨角色移動（相機不跟隨）。
    map.position = Vector2(size.x / 2, size.y / 2) - center;
  }
}
