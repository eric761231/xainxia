import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show Color;

import '../network/packets/client/c_enter_portal.dart';
import '../network/packets/client/c_face.dart';
import '../network/packets/client/c_move.dart';
import '../network/packets/server/s_char_face.dart';
import '../network/packets/server/s_char_move.dart';
import '../network/packets/server/s_enter_game.dart';
import '../network/packets/server/s_map_info.dart';
import '../network/packets/server/s_map_tiles.dart';
import '../network/packets/server/s_monster_pack.dart';
import '../network/packets/server/s_npc_pack.dart';
import '../network/packets/server/s_pc_pack.dart';
import '../network/packets/server/s_property_pack.dart';
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
    this.onTileTap,
    this.onTileSecondaryTap,
    this.monsterAt,
    this.onAttack,
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

  /// 格子點擊攔截（洞府布置模式）；回傳 true 表示已處理。
  final bool Function(int tx, int ty)? onTileTap;

  /// 右鍵／長按某格（角色選單）。
  final void Function(int tx, int ty, Vector2 screenPos)? onTileSecondaryTap;

  /// 查該格上的可攻擊怪物 objId；沒有回 0。
  final int Function(int tx, int ty)? monsterAt;

  /// 走到相鄰格後發動攻擊。
  final void Function(int objId)? onAttack;

  /// 玩家移動或轉向後回報 (x, y, facing)，供小地圖標記玩家位置。
  final void Function(int x, int y, int facing)? onPlayerMoved;

  /// 人物外觀鍵（依所選角色 sex 推導），往下傳給 IsoMapComponent。
  final String appearanceKey;

  /// 已送出 C_ENTER_PORTAL、等待 S_MAP_CHANGE 期間的防重複旗標。
  bool _portalPending = false;

  IsoMapComponent? _map;
  int _localHp = 0;
  int _localHpMax = 0;
  int _localMp = 0;
  int _localMpMax = 0;

  /// 更新本機角色頭頂狀態條；場景載入中時會保留到地圖元件建立完成。
  void setLocalPlayerVitals({
    required int hp,
    required int hpMax,
    required int mp,
    required int mpMax,
  }) {
    _localHp = hp;
    if (hpMax > 0) _localHpMax = hpMax;
    _localMp = mp;
    if (mpMax > 0) _localMpMax = mpMax;
    _map?.setLocalPlayerVitals(
      hp: _localHp,
      hpMax: _localHpMax,
      mp: _localMp,
      mpMax: _localMpMax,
    );
  }

  void setCharacterHp(int objId, int hp, int hpMax) {
    if (objId == enterGame.objId) {
      setLocalPlayerVitals(
        hp: hp,
        hpMax: hpMax,
        mp: _localMp,
        mpMax: _localMpMax,
      );
      return;
    }
    _map?.setRemotePlayerHp(objId, hp, hpMax);
  }

  void setCharacterMp(int objId, int mp, int mpMax) {
    if (objId == enterGame.objId) {
      setLocalPlayerVitals(
        hp: _localHp,
        hpMax: _localHpMax,
        mp: mp,
        mpMax: mpMax,
      );
      return;
    }
    _map?.setRemotePlayerMp(objId, mp, mpMax);
  }

  /// 其他玩家移動廣播（S_CHAR_MOVE）。
  void applyRemoteMove(SCharMove move) {
    _map?.moveRemotePlayer(move.charName, move.x, move.y, move.facing);
  }

  /// 怪物名單（S_MONSTER_PACK）。逐筆 upsert。
  void applyMonsters(List<MonsterObject> monsters) =>
      _map?.applyMonsters(monsters);

  /// 怪物走了一步（S_NPC_MOVE）。
  void moveMonster(int objId, int x, int y, int heading) =>
      _map?.moveMonster(objId, x, y, heading);

  /// 怪物血量變化（S_HP_UPDATE 是廣播的，含怪物）。
  void setMonsterHp(int objId, int hp, int maxHp) =>
      _map?.setMonsterHp(objId, hp, maxHp);

  void playLocalPlayerAttack() => _map?.playLocalPlayerAttack();
  void playLocalPlayerHurt() => _map?.playLocalPlayerHurt();
  void playLocalPlayerDeath() => _map?.playLocalPlayerDeath();

  /// 怪物攻擊演出（先面向目標再揮）。
  void playMonsterAttack(int objId, int targetObjId) =>
      _map?.playMonsterAttack(objId, targetObjId);

  /// 怪物被打中的演出。
  void playMonsterHurt(int objId) => _map?.playMonsterHurt(objId);

  /// 怪物死亡或離場（S_OBJECT_REMOVE）。死亡的會先留下屍體再消失。
  void removeMonster(int objId) => _map?.removeMonster(objId);

  /// 換圖時清掉場上的怪。
  void clearMonsters() => _map?.clearMonsters();

  /// NPC 名單（S_NPC_PACK）。逐筆 upsert。
  void applyNpcs(List<NpcObject> npcs) => _map?.applyNpcs(npcs);

  /// NPC 走了一步或轉身（S_NPC_MOVE）。
  void moveNpc(int objId, int x, int y, int heading) =>
      _map?.moveNpc(objId, x, y, heading);

  /// NPC 離場（S_OBJECT_REMOVE）。
  void removeNpc(int objId) => _map?.removeNpc(objId);

  /// 換圖時清掉場上的 NPC。
  void clearNpcs() => _map?.clearNpcs();

  /// 物件頭上的對話泡泡（S_BUBBLE_DIALOG）。
  void showBubble(int objId, String text) => _map?.showBubble(objId, text);

  /// 該格上的其他玩家角色名；沒有回 null。供右鍵選單用。
  String? remotePlayerNameAt(int x, int y) => _map?.remotePlayerNameAt(x, y);

  /// 同圖玩家名單（S_PC_PACK）。整包取代，不是增量。
  void applyRemotePlayers(SPcPack pack, {required String selfName}) {
    _map?.applyRemotePlayers(pack.players, selfName: selfName);
  }

  /// 套用伺服器指定的場景底圖（S_MAP_INFO 的 gfxid）。
  ///
  /// 底圖在進圖後才由 S_MAP_INFO 帶來，晚於 WorldScene 建立，故走此非同步後補路徑。
  void applyMapBackground(int gfxid) {
    _map?.applyBackground(gfxid);
  }

  /// 套用伺服器推送的場景物件（S_PROPERTY_PACK）。
  void applyServerProperties(List<PropertyObject> properties) {
    _map?.applyServerProperties(properties);
  }

  /// 移除單一世界物件（S_OBJECT_REMOVE）。
  void removeServerObject(int objId) {
    _map?.removeServerObject(objId);
  }

  /// 清空畫面上所有伺服器場景物件（換圖時呼叫，避免舊圖物件殘留）。
  void clearServerProperties() {
    _map?.clearServerProperties();
  }

  /// 套用伺服器送來的圖磚（S_MAP_TILES）。
  void applyMapTiles(SMapTiles tiles) {
    _map?.applyMapTiles(tiles);
  }

  /// 套用伺服器指定的地形碰撞（S_MAP_INFO 的 blocked／S_MAP_COLLISION）。
  void applyTerrainCollision(List<(int, int)> blocked) {
    _map?.applyTerrainCollision(blocked);
  }

  /// 目前的地形碰撞格（地圖座標）。
  List<(int, int)> get terrainBlocked => _map?.terrainBlocked ?? const [];

  /// 高亮一組格子（地圖座標）。
  void highlightTiles(Iterable<(int, int)> cells, Color color) {
    _map?.highlightTiles(cells, color);
  }

  void clearHighlight() => _map?.clearHighlight();

  /// 顯示／清除半透明的家具放置預覽。
  Future<void> showGhost(int pngid, int x, int y) async =>
      _map?.showGhost(pngid, x, y);

  void clearGhost() => _map?.clearGhost();

  /// 把某個已放置家具設為半透明（搬動中），或還原為 1.0。
  void setObjectOpacity(int objId, double opacity) {
    _map?.setObjectOpacity(objId, opacity);
  }

  /// 該格是否不可通行（含地形與家具）。供放置預覽做本地合法性提示。
  bool isTileBlocked(int x, int y) => _map?.isTileBlocked(x, y) ?? true;

  /// 該格是否在地圖的合法可走範圍內。
  bool isInMap(int x, int y) => _map?.isInMap(x, y) ?? false;

  /// 玩家自己所在的格（地圖座標）。
  (int, int)? get playerCell => _map?.playerCell;

  /// 伺服器對「自己」的移動修正（S_CHAR_MOVE 回送合法座標）。
  ///
  /// 只在伺服器座標與本地不同時才拉，避免每次正常移動的回音都造成抖動。
  void applySelfCorrection(SCharMove move) {
    final map = _map;
    if (map == null) return;
    if (map.playerTileX == move.x && map.playerTileY == move.y) return;
    debugPrint(
        '伺服器移動修正：(${map.playerTileX},${map.playerTileY}) -> (${move.x},${move.y})');
    map.snapPlayerTo(move.x, move.y, facing: move.facing);
  }

  /// 其他玩家轉向廣播（S_CHAR_FACE）。
  void applyRemoteFace(SCharFace face) {
    _map?.faceRemotePlayer(face.charName, face.facing);
  }

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
      charName: enterGame.charName,
      onPlayerStep: _onPlayerStep,
      onPlayerFace: _onPlayerFace,
      onInteract: _onInteract,
      onTileTap: onTileTap,
      onTileSecondaryTap: onTileSecondaryTap,
      monsterAt: monsterAt,
      onAttack: onAttack,
    );
    _map!.setLocalPlayerVitals(
      hp: _localHp,
      hpMax: _localHpMax,
      mp: _localMp,
      mpMax: _localMpMax,
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
