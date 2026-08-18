import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../network/packets/client/c_enter_portal.dart';
import '../network/packets/client/c_face.dart';
import '../network/packets/client/c_move.dart';
import '../network/packets/server/s_char_face.dart';
import '../network/packets/server/s_char_move.dart';
import '../network/packets/server/s_enter_game.dart';
import '../network/packets/server/s_map_info.dart';
import '../services/game_session_service.dart';
import 'map/iso_map_component.dart';
import 'map/iso_map_data.dart';

/// 世界場景：載入等距地圖並放置玩家出生點。
class WorldSceneComponent extends PositionComponent {
  WorldSceneComponent({
    required this.enterGame,
    this.sessionService,
    this.appearanceKey = 'male',
    this.spawnFacing = 2,
    this.portalsProvider,
    this.onInteract,
    this.onPlayerMoved,
  });

  final SEnterGame enterGame;
  final GameSessionService? sessionService;

  /// 出生面向（0-7），由伺服器 S_MAP_CHANGE 的 facing 傳入。
  final int spawnFacing;

  /// 取得當前地圖的傳送點清單（由 MyGame 依 S_MAP_INFO 提供），用於踏格觸發偵測。
  final List<PortalPoint> Function()? portalsProvider;

  /// 走近互動物件（採集／對話／攻擊）→ 交由上層送封包／開介面。
  final void Function(MapInteractable interactable)? onInteract;

  /// 玩家移動或轉向後回報 (x, y, facing)，供小地圖標記玩家位置。
  final void Function(int x, int y, int facing)? onPlayerMoved;

  /// 人物外觀鍵（依所選角色 sex 推導），往下傳給 IsoMapComponent。
  final String appearanceKey;

  /// 已送出 C_ENTER_PORTAL、等待 S_MAP_CHANGE 期間的防重複旗標。
  bool _portalPending = false;

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
      spawnFacing: spawnFacing,
      appearanceKey: appearanceKey,
      onPlayerStep: _onPlayerStep,
      onPlayerFace: _onPlayerFace,
      onInteract: _onInteract,
    );
    add(_map!);
  }

  /// 走近互動物件（採集／對話／攻擊）→ 交給上層送封包／開介面。
  void _onInteract(MapInteractable it) {
    onInteract?.call(it);
  }

  void _onPlayerStep(int x, int y, int facing) {
    sessionService?.send(CMove.build(x: x, y: y, facing: facing));
    onPlayerMoved?.call(x, y, facing);
    _checkPortalTrigger(x, y, facing);
  }

  /// 踏格後偵測是否進入某傳送點的觸發範圍；是則送 C_ENTER_PORTAL（伺服器權威換圖）。
  void _checkPortalTrigger(int x, int y, int facing) {
    if (_portalPending) return;
    final portals = portalsProvider?.call() ?? const [];
    for (final p in portals) {
      if (p.inRange(x, y)) {
        _portalPending = true;
        sessionService?.send(
            CEnterPortal.build(portalId: p.portalId, facing: facing));
        debugPrint('進入傳送點 portalId=${p.portalId}「${p.name}」→ 送 C_ENTER_PORTAL');
        // 安全逾時：若伺服器未回 S_MAP_CHANGE（會重建本場景），解除旗標避免卡死。
        Future.delayed(const Duration(seconds: 3), () => _portalPending = false);
        break;
      }
    }
  }

  void _onPlayerFace(int facing) {
    sessionService?.send(CFace.build(facing: facing));
    final m = _map;
    if (m != null) onPlayerMoved?.call(m.playerTileX, m.playerTileY, facing);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (size.x <= 0 || size.y <= 0) return;
    final map = _map;
    if (map == null) return;
    // 相機跟隨玩家：玩家固定在畫面中央，地圖在底下移動。
    // 未載入玩家（初始一幀）時退回以地圖內容置中，避免跳動。
    final focus = map.playerLocalPosition ?? map.contentCenterLocal;
    if (focus == null) return;
    // 乘上 renderScale：focus 為未縮放 local 座標，視覺中心需按縮放放大。
    map.position = Vector2(size.x / 2, size.y / 2) - focus * map.scale.x;
  }
}
