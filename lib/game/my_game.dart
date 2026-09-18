import 'dart:async';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xianxia_game/l10n/app_localizations.dart';

import '../ui/widgets/shared/context_menu.dart';
import 'map/tile_overlay_layer.dart';
import 'party_member.dart';
import 'tile_tool_mode.dart';
import '../ui/layout/char_create/char_create_ui_preloader.dart';
import '../config/app_log.dart';
import '../config/server_connection_loader.dart';
import '../models/server_status.dart';
import '../models/game_character.dart';
import '../network/packets/server/s_enter_game.dart';
import '../network/packets/server/s_map_change.dart';
import '../network/packets/server/s_map_info.dart';
import '../network/packets/server/s_monster_pack.dart';
import '../network/packets/server/s_npc_move.dart';
import '../network/packets/server/s_npc_pack.dart';
import '../network/packets/server/s_object_remove.dart';
import '../network/packets/server/s_map_collision.dart';
import '../network/packets/server/s_map_tiles.dart';
import '../network/packets/server/s_party.dart';
import '../network/packets/server/s_game_over.dart';
import '../network/packets/server/s_pc_pack.dart';
import '../network/packets/server/s_wave.dart';
import '../network/packets/server/s_placeable_list.dart';
import '../network/packets/server/s_property_pack.dart';
import '../network/packets/server/s_property_update.dart';
import '../network/packets/server/s_server_shutdown.dart';
import '../services/auth_service.dart';
import '../services/character_service.dart';
import '../services/game_session_service.dart';
import '../services/game_world_service.dart';
import '../services/server_list_service.dart';
import 'world_scene.dart';

class MyGame extends FlameGame {
  double progress = 0.0;
  final ValueNotifier<int?> transitionPortraitSex = ValueNotifier<int?>(null);
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> transitionMessageNotifier = ValueNotifier<String>(
    '載入中...',
  );
  final ValueNotifier<List<ServerStatus>> serverStatusesNotifier =
      ValueNotifier<List<ServerStatus>>([]);
  SpriteComponent? loadingSprite;
  PositionComponent? playerComponent;
  WorldSceneComponent? worldScene;
  AppLocalizations? loc;

  /// 當前地圖資訊（小地圖：地名 + 尺寸 + 傳送點），由 S_MAP_INFO 更新。
  final ValueNotifier<SMapInfo?> mapInfoNotifier = ValueNotifier<SMapInfo?>(null);

  /// 玩家在當前地圖的格座標 + 面向，供小地圖畫玩家箭頭。
  final ValueNotifier<({int x, int y, int facing})?> playerMarkNotifier =
      ValueNotifier<({int x, int y, int facing})?>(null);

  /// 執行 GM 指令所需的最低權限等級。
  /// 必須與伺服器 `GmCommandHandler.REQUIRED_ACCESS_LEVEL` 一致 —— 改一邊要記得改另一邊。
  static const gmAccessLevel = 100;

  /// 帳號權限等級，登入時由 S_LOGIN_RESULT 帶入；登出重設為 0。
  final ValueNotifier<int> accessLevelNotifier = ValueNotifier<int>(0);

  /// 是否為 GM。這只是<b>介面可見性</b>判斷，不是安全機制 ——
  /// 伺服器收到 GM 指令時一律重驗 access_level。
  bool get isGm => accessLevelNotifier.value >= gmAccessLevel;

  /// GM 面板是否開啟（GameHudOverlay 是 StatelessWidget，開關狀態需外部持有）。
  final ValueNotifier<bool> gmPanelOpenNotifier = ValueNotifier<bool>(false);

  /// 可布置的地圖（目前只有修練洞府）。與伺服器 C_PlaceProperty 的限制一致。
  static const decoratableMapId = 0;

  /// 秘境挑戰地圖，由伺服器在 S_ENTER_GAME 告知（-1 = 沒有啟用）。
  ///
  /// 刻意不寫成常數 —— 這張圖是 `wave_config` 的一列，企劃改了資料之後
  /// 前端若還記著舊的編號，「離開秘境」按鈕就會出現在錯的地圖上。
  int get challengeMapId => _lastEnterGame?.challengeMapId ?? -1;

  /// 洞府布置面板是否開啟。
  final ValueNotifier<bool> decorPanelOpenNotifier = ValueNotifier<bool>(false);

  /// 社交面板（好友／門派）是否開啟。
  final ValueNotifier<bool> socialPanelOpenNotifier =
      ValueNotifier<bool>(false);

  /// 背包面板是否開啟。
  final ValueNotifier<bool> inventoryPanelOpenNotifier =
      ValueNotifier<bool>(false);

  /// 修練面板（練氣／靈寵）是否開啟。
  final ValueNotifier<bool> cultivationPanelOpenNotifier =
      ValueNotifier<bool>(false);

  /// 目前要顯示的右鍵／長按選單；null = 沒有選單。
  ///
  /// 由 HUD 最上層畫出來，任何地方（世界角色、隊伍列）要跳選單就塞值。
  final ValueNotifier<ContextMenuRequest?> contextMenuNotifier =
      ValueNotifier<ContextMenuRequest?>(null);

  /// 波次狀態（倖存者玩法）。null = 這張地圖沒有波次。
  final ValueNotifier<SWave?> waveNotifier = ValueNotifier<SWave?>(null);

  /// 挑戰結算。非 null 時 HUD 蓋上結算畫面；按下按鈕才清空。
  ///
  /// 收到這個值時角色**已經**回到洞府了 —— 結算畫面只是成績單，
  /// 不是「還沒離開地圖」的等待狀態。
  final ValueNotifier<SGameOver?> gameOverNotifier =
      ValueNotifier<SGameOver?>(null);

  /// 隊伍成員。由伺服器的 S_PARTY 整包填入；空清單＝沒有隊伍。
  final ValueNotifier<List<PartyMember>> partyMembersNotifier =
      ValueNotifier<List<PartyMember>>(const []);

  /// 自己的角色 objId（由 S_ENTER_GAME 帶入）。
  ///
  /// 隊伍欄要靠它分辨哪一列是自己 —— 自己那列不該出現「驅逐」。
  int selfObjId = 0;

  void showContextMenu(ContextMenuRequest request) =>
      contextMenuNotifier.value = request;

  void dismissContextMenu() => contextMenuNotifier.value = null;

  /// 目前點擊格子要做什麼。取代原本的「放置」「拆除」兩個布林旗標 ——
  /// 加上搬動與 GM 碰撞編輯後會有四種互斥狀態，用 enum 讓互斥由型別保證。
  final ValueNotifier<TileTool> tileToolNotifier =
      ValueNotifier<TileTool>(TileTool.none);

  /// 放置模式選中的家具 propertyId；null = 尚未選。
  final ValueNotifier<int?> pendingPropertyIdNotifier =
      ValueNotifier<int?>(null);

  /// 放置預覽目前落在哪一格；null = 尚未落下預覽。
  final ValueNotifier<(int, int)?> pendingCellNotifier =
      ValueNotifier<(int, int)?>(null);

  /// 搬動中的家具 objId；0 = 沒有在搬。
  final ValueNotifier<int> movingObjIdNotifier = ValueNotifier<int>(0);

  /// 切換工具模式，並清乾淨上一個模式的殘留狀態。
  ///
  /// 這是「互斥」唯一被強制的地方 —— 所有進入／離開模式都要走這裡，
  /// 否則會留下半透明的家具或沒清掉的預覽。
  void setTileTool(TileTool tool) {
    if (tileToolNotifier.value == tool) return;
    cancelPendingPlacement();
    cancelPendingMove();
    tileToolNotifier.value = tool;
    if (tool != TileTool.collision) {
      worldScene?.clearHighlight();
    } else {
      _refreshCollisionHighlight();
    }
  }

  /// 確認放置：把預覽的位置真的送出去（面板「確定」鈕）。
  void confirmPendingPlacement() {
    final propertyId = pendingPropertyIdNotifier.value;
    final cell = pendingCellNotifier.value;
    if (propertyId == null || cell == null) return;
    gameWorldService?.placeProperty(propertyId, cell.$1, cell.$2);
    cancelPendingPlacement();
  }

  /// 取消尚未確認的放置預覽。
  void cancelPendingPlacement() {
    pendingCellNotifier.value = null;
    pendingPropertyIdNotifier.value = null;
    worldScene?.clearGhost();
    worldScene?.clearHighlight();
  }

  /// 取消搬動：把半透明的家具還原。
  void cancelPendingMove() {
    final objId = movingObjIdNotifier.value;
    if (objId != 0) {
      worldScene?.setObjectOpacity(objId, 1.0);
      movingObjIdNotifier.value = 0;
    }
    worldScene?.clearHighlight();
  }

  /// 右鍵／長按世界上的某一格：命中角色就跳選單。
  ///
  /// 命中順序：自己 → 其他玩家 → 都不是就什麼都不做（維持原本的點擊行為）。
  void handleCharacterSecondaryTap(int tx, int ty, Vector2 screenPos) {
    final pos = Offset(screenPos.x, screenPos.y);

    final self = worldScene?.playerCell;
    if (self != null && self.$1 == tx && self.$2 == ty) {
      _showSelfMenu(pos);
      return;
    }

    final other = _remotePlayerAt(tx, ty);
    if (other != null) {
      _showOtherPlayerMenu(pos, other);
      return;
    }

    if (isGm) _handleGmTeleportTap(tx, ty);
  }

  /// GM 在同一格連點兩下右鍵的判定時間窗（毫秒）。
  static const int gmTeleportDoubleClickMs = 450;
  (int, int)? _gmTeleportCell;
  DateTime? _gmTeleportAt;

  /// GM：在同一格空地右鍵連點兩下 → 傳送過去（`tp <目前地圖> x y`）。
  ///
  /// 走伺服器既有的 GM 傳送：無視碰撞與距離，權限由伺服器每次重驗。
  /// 要點兩下是為了不跟右鍵選單搶操作，單點右鍵空地也不會誤傳送。
  void _handleGmTeleportTap(int tx, int ty) {
    final now = DateTime.now();
    final last = _gmTeleportAt;
    if (_gmTeleportCell == (tx, ty) &&
        last != null &&
        now.difference(last).inMilliseconds <= gmTeleportDoubleClickMs) {
      _gmTeleportCell = null;
      _gmTeleportAt = null;
      final mapId = _lastEnterGame?.mapId;
      if (mapId == null) return;
      gameWorldService?.sendGmCommand('tp $mapId $tx $ty');
      return;
    }
    _gmTeleportCell = (tx, ty);
    _gmTeleportAt = now;
  }

  String? _remotePlayerAt(int x, int y) => worldScene?.remotePlayerNameAt(x, y);

  /// 右鍵自己：只有 GM 有東西可看。
  ///
  /// 這是 GM 面板唯一的入口 —— 小地圖旁原本那顆快捷鈕已移除，
  /// 因為它會擠掉版面，而且一般玩家根本不該看到。
  void _showSelfMenu(Offset pos) {
    if (!isGm) return;
    showContextMenu(ContextMenuRequest(
      position: pos,
      title: 'GM 選單',
      items: [
        ContextMenuItem('GM 面板',
            () => gmPanelOpenNotifier.value = !gmPanelOpenNotifier.value),
        ContextMenuItem('碰撞編輯', () {
          setTileTool(tileToolNotifier.value == TileTool.collision
              ? TileTool.none
              : TileTool.collision);
        }),
      ],
    ));
  }

  /// 右鍵其他玩家：跟隨／組隊／交易。目前只有介面，點了顯示系統訊息。
  void _showOtherPlayerMenu(Offset pos, String name) {
    void stub(String action) => gameWorldService
        ?.localSystemMessage('［$action］功能尚未開放（對象：$name）');

    showContextMenu(ContextMenuRequest(
      position: pos,
      title: name,
      items: [
        ContextMenuItem('跟隨', () => stub('跟隨')),
        ContextMenuItem('組隊', () => gameWorldService?.partyInvite(name)),
        ContextMenuItem('交易', () => stub('交易')),
      ],
    ));
  }

  // ── 隊伍 ────────────────────────────────────────────────────────

  /// 伺服器送來隊伍狀態。整包換掉 —— 伺服器每次變動都重送全部成員。
  void _onServerParty(SParty party) {
    partyMembersNotifier.value = [
      for (final m in party.members)
        PartyMember.fromPacket(m,
            leaderObjId: party.leaderObjId, selfObjId: selfObjId),
    ];
  }

  /// 收到組隊邀請 —— 借用右鍵選單當提示，不必另做一個對話框元件。
  void _onServerPartyInvite(SPartyInvite invite) {
    showContextMenu(ContextMenuRequest(
      // 沒有滑鼠位置可用，固定顯示在畫面左上偏中的位置
      position: const Offset(240, 160),
      title: '${invite.inviterName} 邀請組隊',
      items: [
        ContextMenuItem('接受', () => gameWorldService?.partyAccept()),
        ContextMenuItem('拒絕', () => gameWorldService?.partyDecline(),
            danger: true),
      ],
    ));
  }

  void kickPartyMember(String name) => gameWorldService?.partyKick(name);

  void promotePartyLeader(String name) => gameWorldService?.partyPromote(name);

  void leaveParty() => gameWorldService?.partyLeave();

  // ── 秘境挑戰 ──────────────────────────────────────────────────────

  /// 進入秘境。同時清掉上一輪的結算畫面。
  void enterChallenge() {
    gameOverNotifier.value = null;
    gameWorldService?.challengeEnter();
  }

  /// 還沒死就主動退出秘境。
  void leaveChallenge() {
    gameOverNotifier.value = null;
    gameWorldService?.challengeLeave();
  }

  /// 關掉結算畫面，留在洞府。
  void dismissGameOver() => gameOverNotifier.value = null;

  /// 目前是否站在可布置的地圖上（決定 HUD 的布置按鈕是否顯示）。
  bool get canDecorate => _lastEnterGame?.mapId == decoratableMapId;

  /// 布置／GM 模式下的格子點擊處理；回傳 true 表示已吃掉這次點擊。
  ///
  /// 前端的合法性判斷只是「提示」，不是授權 —— 伺服器一律會再驗一次。
  /// 前端先擋能省一次往返，兩邊暫時不一致也只是玩家多看到一則系統訊息。
  bool handleDecorTileTap(int tx, int ty) {
    switch (tileToolNotifier.value) {
      case TileTool.none:
        return false;

      case TileTool.place:
        return _handlePlaceTap(tx, ty);

      case TileTool.move:
        return _handleMoveTap(tx, ty);

      case TileTool.remove:
        final objId = objIdAt(tx, ty);
        if (objId != 0) {
          gameWorldService?.removeProperty(objId);
        }
        return true;

      case TileTool.collision:
        return _handleCollisionTap(tx, ty);
    }
  }

  /// 放置：兩段式 —— 第一次點擊落下預覽，再點同一格才真的送出。
  ///
  /// 手機上單點即放太容易誤觸，且玩家看不到家具會落在哪、佔幾格。
  bool _handlePlaceTap(int tx, int ty) {
    final propertyId = pendingPropertyIdNotifier.value;
    if (propertyId == null) return true;

    final current = pendingCellNotifier.value;
    if (current != null && current.$1 == tx && current.$2 == ty) {
      gameWorldService?.placeProperty(propertyId, tx, ty);
      cancelPendingPlacement();
      return true;
    }

    pendingCellNotifier.value = (tx, ty);
    final item = _placeableById(propertyId);
    worldScene?.showGhost(item?.pngid ?? propertyId, tx, ty);
    _paintFootprint(tx, ty, item?.footprintW ?? 1, item?.footprintH ?? 1,
        ignoreObjId: 0);
    return true;
  }

  /// 搬動：第一次點擊選中家具，第二次點擊決定新位置。
  bool _handleMoveTap(int tx, int ty) {
    final moving = movingObjIdNotifier.value;

    if (moving == 0) {
      final objId = objIdAt(tx, ty);
      if (objId == 0) return true;
      movingObjIdNotifier.value = objId;
      worldScene?.setObjectOpacity(objId, 0.4);
      final p = currentProperties[objId];
      if (p != null) {
        // 先把「目前佔了哪幾格」畫出來，玩家才知道自己在搬多大一塊
        _paintCells(_footprintCells(p.x, p.y, p.footprintW, p.footprintH),
            TileOverlayLayer.movingColor);
      }
      return true;
    }

    // 再點一次同一件家具 = 取消
    if (objIdAt(tx, ty) == moving) {
      cancelPendingMove();
      return true;
    }

    final p = currentProperties[moving];
    if (p != null) {
      gameWorldService?.moveProperty(moving, tx, ty);
    }
    cancelPendingMove();
    return true;
  }

  /// GM 碰撞編輯：點擊切換該格的地形通行狀態。
  bool _handleCollisionTap(int tx, int ty) {
    final blocked = worldScene?.terrainBlocked ?? const <(int, int)>[];
    final already = blocked.any((c) => c.$1 == tx && c.$2 == ty);
    gameWorldService?.setCollision(tx, ty, !already);
    return true;
  }

  /// 依 footprint 畫出佔格，並依本地碰撞判斷染綠（可放）或紅（不可放）。
  void _paintFootprint(int x, int y, int w, int h, {required int ignoreObjId}) {
    final cells = _footprintCells(x, y, w, h);
    final scene = worldScene;
    if (scene == null) return;

    var ok = true;
    for (final (cx, cy) in cells) {
      if (!scene.isInMap(cx, cy) || scene.isTileBlocked(cx, cy)) {
        ok = false;
        break;
      }
    }
    _paintCells(
      cells,
      ok ? TileOverlayLayer.okColor : TileOverlayLayer.blockedColor,
    );
  }

  void _paintCells(List<(int, int)> cells, Color color) {
    worldScene?.highlightTiles(cells, color);
  }

  /// 以 (x,y) 為錨點、往 x/y 遞減展開的佔格。
  /// 與伺服器 DecorationInstance.occupies() 同一套展開方向。
  static List<(int, int)> _footprintCells(int x, int y, int w, int h) {
    final cells = <(int, int)>[];
    for (var j = 0; j < (h < 1 ? 1 : h); j++) {
      for (var i = 0; i < (w < 1 ? 1 : w); i++) {
        cells.add((x - i, y - j));
      }
    }
    return cells;
  }

  /// GM 碰撞編輯模式下，把整張地圖目前的地形阻擋格畫出來。
  void _refreshCollisionHighlight() {
    final scene = worldScene;
    if (scene == null) return;
    scene.highlightTiles(scene.terrainBlocked, TileOverlayLayer.terrainColor);
  }

  /// 從可放置清單查一件家具的定義（取 pngid 與 footprint）。
  PlaceableItem? _placeableById(int propertyId) {
    for (final it in gameWorldService?.placeableNotifier.value ?? const []) {
      if (it.propertyId == propertyId) return it;
    }
    return null;
  }

  /// 當前地圖的傳送點清單（供 WorldScene 踏格觸發偵測）。
  List<PortalPoint> currentPortals = const [];

  /// 當前地圖的伺服器物件（key = objId）。
  /// 由三個 Pack 包建立，再由 S_NPC_MOVE / S_PROPERTY_UPDATE / S_OBJECT_REMOVE
  /// 增量更新；換圖時一併清空。尚未接渲染，目前僅維護資料。
  final Map<int, NpcObject> currentNpcs = {};
  final Map<int, MonsterObject> currentMonsters = {};
  final Map<int, PropertyObject> currentProperties = {};

  /// 最近一次進場資料，換圖時沿用同角色 objId/charName。
  SEnterGame? _lastEnterGame;

  ServerConnectionConfig? connectionConfig;
  GameSessionService? sessionService;
  AuthService? authService;
  CharacterService? characterService;
  GameWorldService? gameWorldService;
  ServerListService? serverListService;

  List<ServerStatus> serverStatuses = [];
  final ValueNotifier<String?> selectedServerNotifier = ValueNotifier<String?>(
    null,
  );

  String? _selectedServer;

  static const _mapAssets = ['assets/images/loading.png'];

  String? get selectedServer => _selectedServer;

  set selectedServer(String? value) {
    _selectedServer = value;
    selectedServerNotifier.value = effectiveSelectedServer;
  }

  String? get effectiveSelectedServer {
    if (selectedServer != null) {
      final picked = serverListService?.findByName(selectedServer!);
      if (picked == null || picked.selectable) {
        return selectedServer;
      }
    }
    final selectable = serverStatuses.where((s) => s.selectable);
    if (selectable.isNotEmpty) {
      return selectable.first.name;
    }
    if (serverStatuses.isNotEmpty) {
      return serverStatuses.first.name;
    }
    return connectionConfig?.defaultServer?.name;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    connectionConfig = await ServerConnectionLoader.load();
    sessionService = GameSessionService(connectionConfig!);
    // 伺服器權威換圖 + 小地圖資訊：常駐 handler（跨換圖存活）。
    sessionService!.dispatcher.onMapChange = _onServerMapChange;
    sessionService!.dispatcher.onMapInfo = _onServerMapInfo;
    sessionService!.dispatcher.onMapCollision = _onServerMapCollision;
    sessionService!.dispatcher.onMapTiles = _onServerMapTiles;
    sessionService!.dispatcher.onParty = _onServerParty;
    sessionService!.dispatcher.onWave = (w) => waveNotifier.value = w;
    sessionService!.dispatcher.onGameOver = (r) => gameOverNotifier.value = r;
    sessionService!.dispatcher.onPcPack = _onServerPcPack;
    sessionService!.dispatcher.onPartyInvite = _onServerPartyInvite;
    sessionService!.dispatcher.onServerShutdown = _onServerShutdown;
    // 地圖物件：清單三包 + 增量更新，同為地圖範圍推送，一併常駐。
    sessionService!.dispatcher.onNpcPack = _onServerNpcPack;
    sessionService!.dispatcher.onMonsterPack = _onServerMonsterPack;
    sessionService!.dispatcher.onPropertyPack = _onServerPropertyPack;
    sessionService!.dispatcher.onNpcMove = _onServerNpcMove;
    sessionService!.dispatcher.onPropertyUpdate = _onServerPropertyUpdate;
    sessionService!.dispatcher.onObjectRemove = _onServerObjectRemove;
    // 連線被伺服器關閉／異常（含 -9／崩潰）→ 關閉遊戲視窗。
    sessionService!.onConnectionLost = _onConnectionLost;
    authService = AuthService(connectionConfig!, sessionService!);
    characterService = CharacterService(sessionService!, connectionConfig!);
    gameWorldService = GameWorldService(sessionService!);

    // 怪物血量：S_HP_UPDATE 是廣播的，除了自己也會帶怪物的血量。
    // 服務層只負責自己的（回寫 liveStats），怪物的狀態在 currentMonsters，
    // 所以在這裡補上。只註冊一次 —— service 的生命週期與 MyGame 相同。
    gameWorldService!.hpUpdateNotifier.addListener(_syncMonsterHp);
    gameWorldService!.hpUpdateNotifier.addListener(_syncLocalPlayerHpAnimation);
    gameWorldService!.hpUpdateNotifier.addListener(_syncCharacterHpBar);
    gameWorldService!.mpUpdateNotifier.addListener(_syncCharacterMpBar);
    gameWorldService!.liveStatsNotifier.addListener(_syncLocalPlayerVitals);
    gameWorldService!.attackNotifier.addListener(_syncLocalPlayerAttackAnimation);
    gameWorldService!.attackNotifier.addListener(_syncMonsterCombatAnimations);
    // NPC／怪物頭上的對話泡泡：以前收到了但沒有任何地方畫出來
    gameWorldService!.bubbleDialogNotifier.addListener(_showBubbleDialog);
    serverListService = ServerListService(connectionConfig!);
    serverStatuses = serverListService!.buildFallbackStatuses();
    serverStatusesNotifier.value = serverStatuses;
    selectedServer =
        connectionConfig!.defaultServer?.name ?? effectiveSelectedServer;

    Future(() async {
      try {
        await Future.wait([
          _simulateProgress(const Duration(seconds: 10)),
          _loadAssetsWithFallback(),
          refreshServerStatuses(),
        ]);
      } catch (e, st) {
        debugPrint('Background load error: $e\n$st');
      } finally {
        progress = 1.0;
        progressNotifier.value = progress;
        await Future.delayed(const Duration(milliseconds: 300));
        overlays.remove('Loading');
        overlays.add('Account');
      }
    });
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final sprite = loadingSprite;
    if (sprite != null && size.x > 0 && size.y > 0) {
      sprite.size = size;
    }
    final world = worldScene;
    if (world != null && size.x > 0 && size.y > 0) {
      world.size = size;
    }
  }

  Future<Vector2> _waitForGameSize() async {
    for (var i = 0; i < 100; i++) {
      if (size.x > 0 && size.y > 0) {
        return size;
      }
      final viewportSize = camera.viewport.size;
      if (viewportSize.x > 0 && viewportSize.y > 0) {
        return viewportSize;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    debugPrint(loc?.gameSizeWarning ?? '警告：無法取得有效 game size，使用預設 1280×720');
    return Vector2(1280, 720);
  }

  Future<void> refreshServerStatuses() async {
    final service = serverListService;
    if (service == null) {
      return;
    }
    serverStatuses = await service.fetchStatuses();
    serverStatusesNotifier.value = serverStatuses;

    final current = selectedServer;
    if (current != null) {
      final picked = service.findByName(current);
      if (picked != null && !picked.selectable) {
        selectedServer = effectiveSelectedServer;
      }
    }
  }

  Future<void> _loadAssetsWithFallback() async {
    final gameSize = await _waitForGameSize();
    debugPrint('Background load gameSize: ${gameSize.x} x ${gameSize.y}');

    try {
      await images.load('loading.png');
      final loadingSpr = Sprite(images.fromCache('loading.png'));
      loadingSprite = SpriteComponent()
        ..sprite = loadingSpr
        ..size = gameSize.clone()
        ..anchor = Anchor.topLeft
        ..position = Vector2.zero();
      add(loadingSprite!);
    } catch (e, st) {
      debugPrint('Failed to load loading.png: $e\n$st');
      loadingSprite = null;
      add(
        RectangleComponent(
            size: gameSize.clone(),
            paint: Paint()..color = Colors.blueAccent,
          )
          ..position = Vector2.zero()
          ..anchor = Anchor.topLeft,
      );
    }

    // _simulateProgress is the single owner of startup progress. Asset
    // loading must not reset the same notifier and replay the bar.
  }

  Future<void> _simulateProgress(Duration total) async {
    const steps = 100;
    final step = total.inMilliseconds ~/ steps;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: step));
      progress = i / steps;
      progressNotifier.value = progress;
    }
  }

  Future<void> runTransition({
    required String message,
    List<String>? assetPaths,
    Future<void> Function(void Function(double progress) report)? loadTask,
    Duration minDuration = const Duration(seconds: 2),
  }) async {
    transitionMessageNotifier.value = message;
    progress = 0;
    progressNotifier.value = 0;
    overlays.remove('Loading');
    overlays.add('Transition');

    final startedAt = DateTime.now();

    if (loadTask != null) {
      await loadTask((value) {
        progress = value;
        progressNotifier.value = value;
      });
    } else {
      final paths = assetPaths ?? const [];
      final total = paths.isEmpty ? 1 : paths.length;
      for (var i = 0; i < paths.length; i++) {
        await _preloadAsset(paths[i]);
        progress = (i + 1) / total;
        progressNotifier.value = progress;
      }
      if (paths.isEmpty) {
        progress = 1;
        progressNotifier.value = 1;
      }
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    progress = 1.0;
    progressNotifier.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 200));
    // 等 ValueListenableBuilder 完成本帧更新，再移除 overlay，避免 dispose 時仍有 dependents。
    await Future<void>.delayed(Duration.zero);
    overlays.remove('Transition');
  }

  Future<void> _preloadAsset(String path) async {
    try {
      if (path.startsWith('assets/')) {
        await rootBundle.load(path);
      } else {
        await images.load(path);
      }
    } catch (e) {
      debugPrint('Optional preload skipped: $path ($e)');
    }
  }

  Future<void> onLoginSuccess() async {
    // 登入對話框關閉後才切 overlay，避免 Navigator / overlay 同帧 dispose。
    await Future<void>.delayed(Duration.zero);
    overlays.remove('Account');

    transitionPortraitSex.value = null;

    final service = characterService;
    if (service == null) {
      return;
    }

    try {
      CharacterListSummary? loadedSummary;
      await runTransition(
        message: loc?.enteringCharacterUI ?? '進入角色介面…',
        loadTask: (report) async {
          loadedSummary = await service.fetchCharacterList();
          final characters = loadedSummary!.characters;
          transitionPortraitSex.value = characters.isEmpty ? null : characters.first.sex;
          await CharCreateUiPreloader.preload(onProgress: report);
        },
      );
      final summary = loadedSummary!;
      if (summary.characters.isEmpty) {
        showCharacterCreate();
      } else {
        showCharacterSelect();
      }
    } catch (e) {
      overlays.remove('Transition');
      debugPrint('${loc?.queryCharListFailed ?? '查詢角色列表失敗'}：$e');
      showCharacterCreate();
    }
  }

  void showCharacterCreate() {
    overlays.remove('CharacterSelect');
    overlays.add('CharacterCreate');
  }

  void showCharacterSelect() {
    overlays.remove('CharacterCreate');
    overlays.add('CharacterSelect');
  }

  bool get isLoggedIn => sessionService?.isConnected ?? false;

  bool get isAccountAuthenticated =>
      sessionService?.isAuthenticated ?? false;

  /// 關閉前清理連線；已登入帳號時送 C_AUTH_LOGOUT 更新伺服器 online_state。
  Future<void> shutdownSession() async {
    final service = authService;
    if (service == null) {
      return;
    }
    try {
      if (isAccountAuthenticated) {
        final result = await service.logout();
        if (!result.success) {
          debugPrint('關閉前登出失敗：${result.message}');
        }
        return;
      }
      if (isLoggedIn) {
        await service.disconnect();
      }
    } catch (e, st) {
      debugPrint('關閉前清理連線失敗：$e\n$st');
      await service.disconnect();
    } finally {
      characterService?.clearCache();
      transitionPortraitSex.value = null;
    }
  }

  /// 離開 App：顯示關閉過場畫面 → 登出 → 關閉。
  /// 過場畫面保持到程式結束（不移除），避免關閉前閃回底層畫面。
  Future<void> exitApplication() async {
    transitionMessageNotifier.value = loc?.closingGame ?? '正在關閉遊戲…';
    progress = 0;
    progressNotifier.value = 0;
    overlays.remove('Loading');
    overlays.add('Transition');

    // 進度條 0 → 1 緩升（約 1.35 秒），營造關閉過場感。
    const steps = 30;
    for (var i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 45));
      progress = i / steps;
      progressNotifier.value = progress;
    }

    await shutdownSession();
    exit(0);
  }

  Future<void> logoutToAccount() async {
    gameWorldService?.unbind();
    await shutdownSession();
    accessLevelNotifier.value = 0;
    gmPanelOpenNotifier.value = false;
    decorPanelOpenNotifier.value = false;
    socialPanelOpenNotifier.value = false;
    cultivationPanelOpenNotifier.value = false;
    inventoryPanelOpenNotifier.value = false;
    dismissContextMenu();
    setTileTool(TileTool.none);

    overlays.remove('GameHud');
    overlays.remove('CharacterCreate');
    overlays.remove('CharacterSelect');
    overlays.remove('Transition');
    worldScene?.removeFromParent();
    worldScene = null;
    overlays.add('Account');
  }

  Future<CharacterResult> deleteCharacter(String characterName) async {
    final service = characterService;
    if (service == null) {
      return CharacterResult(success: false, message: loc?.charServiceUninitialized ?? '角色服務尚未初始化');
    }
    return service.deleteCharacter(characterName);
  }

  Future<CharacterResult> createCharacter({
    required String name,
    required int sex,
    required int attribute,
    required int statsIntel,
    required int statsSpirit,
    required int statsAgility,
    required int statsConstitution,
  }) async {
    final service = characterService;
    if (service == null) {
      return CharacterResult(success: false, message: loc?.charServiceUninitialized ?? '角色服務尚未初始化');
    }
    return service.createCharacter(
      name: name,
      sex: sex,
      attribute: attribute,
      statsIntel: statsIntel,
      statsSpirit: statsSpirit,
      statsAgility: statsAgility,
      statsConstitution: statsConstitution,
    );
  }

  Future<void> enterWorldWithCharacter(String characterName) async {
    final service = characterService;
    if (service == null) {
      throw StateError(loc?.charServiceUninitialized ?? '角色服務尚未初始化');
    }

    overlays.remove('CharacterSelect');
    overlays.remove('CharacterCreate');

    final characters = service.cachedSummary?.characters ?? const <GameCharacter>[];
    transitionPortraitSex.value = characters.where((c) => c.name == characterName).firstOrNull?.sex;
    await runTransition(message: loc?.enteringWorld ?? '進入世界…', assetPaths: _mapAssets);

    final result = await service.selectCharacter(characterName);
    if (!result.success || result.enterGame == null) {
      showCharacterSelect();
      throw Exception(result.message);
    }

    await _activateWorld(result.enterGame!);
  }

  /// 依所選角色 sex 推導人物外觀鍵（找不到時預設 male）。
  String _appearanceKeyFor(String charName) {
    final chars = characterService?.cachedSummary?.characters ?? const [];
    for (final c in chars) {
      if (c.name == charName) {
        return c.sex == 1 ? 'female' : 'male';
      }
    }
    return 'male';
  }

  /// 伺服器換圖：收到 S_MAP_CHANGE → 以同角色 objId/charName 重建世界，帶入到達面向。
  void _onServerMapChange(SMapChange change) {
    final prev = _lastEnterGame;
    // 清空舊圖傳送點，等新圖 S_MAP_INFO 重填，避免用舊座標誤觸發。
    currentPortals = const [];
    // 同理清空舊圖物件，等新圖三個 Pack 包重填，避免殘留。
    currentNpcs.clear();
    currentMonsters.clear();
    currentProperties.clear();
    // 場上的怪也要清 —— 否則舊圖的怪會留在新圖上
    worldScene?.clearMonsters();
    worldScene?.clearNpcs();
    // 畫面上的場景物件元件也要一併清掉，否則舊圖的桌椅會留在新圖上
    worldScene?.clearServerProperties();
    // 圖磚與地形同理：等新圖的封包重填，否則會用舊圖的資料
    currentTiles = null;
    waveNotifier.value = null;
    currentTerrain = const [];
    worldScene?.applyTerrainCollision(const []);
    // 離開洞府就退出布置模式，避免在別的地圖誤點
    decorPanelOpenNotifier.value = false;
    setTileTool(TileTool.none);
    _activateWorld(
      SEnterGame(
        objId: prev?.objId ?? 0,
        charName: prev?.charName ?? '',
        mapId: change.mapId,
        x: change.x,
        y: change.y,
      ),
      facing: change.facing,
    );
  }

  /// 伺服器地圖資訊：收到 S_MAP_INFO → 更新小地圖 + 供 WorldScene 觸發偵測的傳送點清單。
  void _onServerMapInfo(SMapInfo info) {
    currentPortals = info.portals;
    mapInfoNotifier.value = info;
    // 底圖：S_MAP_INFO 可能早於或晚於世界建立，兩邊都補一次即可涵蓋。
    worldScene?.applyMapBackground(info.gfxid);
    // 地形碰撞搭在同一包送來，記下來供世界建立後補套
    currentTerrain = info.blocked;
    worldScene?.applyTerrainCollision(info.blocked);
  }

  /// 目前地圖的地形碰撞格。世界元件可能晚於 S_MAP_INFO 建立，故存一份補畫。
  List<(int, int)> currentTerrain = const [];

  /// 目前地圖的圖磚（S_MAP_TILES）。
  ///
  /// 與 currentTerrain 同樣的理由要留一份：封包可能早於世界元件建立就到了，
  /// 世界建好時要能補套。這也是換圖後重建世界的資料來源。
  SMapTiles? currentTiles;

  /// 伺服器送來地圖圖磚 —— 哪個座標用哪一張圖。
  void _onServerMapTiles(SMapTiles tiles) {
    if (!tiles.isValid) {
      AppLog.d('MAP', 'S_MAP_TILES 沒有 ground 資料，略過');
      return;
    }
    currentTiles = tiles;
    worldScene?.applyMapTiles(tiles);
  }

  /// GM 即時編輯地形後的廣播。
  void _onServerMapCollision(SMapCollision collision) {
    currentTerrain = collision.blocked;
    worldScene?.applyTerrainCollision(collision.blocked);
    // 正在編輯的話，同步更新畫面上的紅色標記
    if (tileToolNotifier.value == TileTool.collision) {
      _refreshCollisionHighlight();
    }
  }

  /// 地圖 NPC 清單：逐筆 upsert。
  ///
  /// 刻意不 clear —— 本封包同時服務兩種情境：進圖時的 N 筆初始化，
  /// 以及之後單一物件出現時的 1 筆增量。整包覆蓋會讓後者清光整張圖。
  /// 舊物件的清除由換圖（_onServerMapChange）與 S_OBJECT_REMOVE 負責。
  void _onServerNpcPack(SNpcPack pack) {
    currentNpcs.addEntries(pack.npcs.map((n) => MapEntry(n.objId, n)));
    worldScene?.applyNpcs(pack.npcs);
  }

  /// 地圖怪物清單：逐筆 upsert（1 筆即為即時生怪）。
  /// 同圖的玩家名單。整包取代 —— 不在名單裡的人會被移除。
  ///
  /// 名單含自己，靠角色名濾掉；名字在伺服器是唯一的（有名稱索引表）。
  void _onServerPcPack(SPcPack pack) {
    worldScene?.applyRemotePlayers(pack, selfName: _lastEnterGame?.charName ?? '');
  }

  void _onServerMonsterPack(SMonsterPack pack) {
    currentMonsters
        .addEntries(pack.monsters.map((m) => MapEntry(m.objId, m)));
    worldScene?.applyMonsters(pack.monsters);
  }

  /// 地圖場景物件清單：逐筆 upsert，並同步畫到畫面上。
  void _onServerPropertyPack(SPropertyPack pack) {
    currentProperties
        .addEntries(pack.properties.map((p) => MapEntry(p.objId, p)));
    worldScene?.applyServerProperties(pack.properties);
  }

  /// NPC／怪物移動：伺服器兩者共用一包，故兩個容器都要查。
  void _onServerNpcMove(SNpcMove move) {
    final npc = currentNpcs[move.objId];
    if (npc != null) {
      currentNpcs[move.objId] =
          npc.copyWith(x: move.x, y: move.y, heading: move.heading);
      worldScene?.moveNpc(move.objId, move.x, move.y, move.heading);
      return;
    }
    final monster = currentMonsters[move.objId];
    if (monster != null) {
      currentMonsters[move.objId] =
          monster.copyWith(x: move.x, y: move.y, heading: move.heading);
      worldScene?.moveMonster(move.objId, move.x, move.y, move.heading);
    }
  }

  /// 場景物件狀態變化（採集進度／是否還能互動）。
  void _onServerPropertyUpdate(SPropertyUpdate update) {
    final property = currentProperties[update.objId];
    if (property != null) {
      currentProperties[update.objId] =
          property.copyWith(value: update.value, action: update.action);
    }
  }

  /// 通用物件移除：不分類型，三個容器都試著移除。
  void _onServerObjectRemove(SObjectRemove remove) {
    currentNpcs.remove(remove.objId);
    currentMonsters.remove(remove.objId);
    currentProperties.remove(remove.objId);
    worldScene?.removeMonster(remove.objId);
    worldScene?.removeNpc(remove.objId);
    worldScene?.removeServerObject(remove.objId);
  }

  /// 查出該格上的伺服器物件編號；查無回傳 0。
  ///
  /// 互動封包（C_GATHER／C_INTERACT／C_USE_SKILL）一律以 objId 指定目標，
  /// 但點擊來源是本地地圖的 MapInteractable（沒有 objId），故在此以格座標對應。
  /// 場景物件優先，其次 NPC，最後怪物。
  ///
  /// 場景物件比對**整個 footprint** 而非只有錨點格：一張 2×3 的桌子在畫面上
  /// 覆蓋 6 格，只認錨點格的話玩家點桌面中央會查不到東西，拆除與搬動都會像
  /// 沒有反應。NPC／怪物維持單格比對（它們本來就是 1×1）。
  int objIdAt(int x, int y) {
    // 多個物件重疊時取錨點 y 最大者 —— 那是畫面上最前面、玩家看到的那一個
    PropertyObject? hit;
    for (final p in currentProperties.values) {
      if (!_occupies(p, x, y)) continue;
      if (hit == null || p.y > hit.y || (p.y == hit.y && p.x > hit.x)) {
        hit = p;
      }
    }
    if (hit != null) return hit.objId;

    for (final n in currentNpcs.values) {
      if (n.x == x && n.y == y) return n.objId;
    }
    for (final m in currentMonsters.values) {
      if (m.x == x && m.y == y) return m.objId;
    }
    return 0;
  }

  /// S_BUBBLE_DIALOG → 說話者頭上的泡泡。
  void _showBubbleDialog() {
    final b = gameWorldService?.bubbleDialogNotifier.value;
    if (b == null || b.text.isEmpty) return;
    worldScene?.showBubble(b.objId, b.text);
  }

  /// 把 S_HP_UPDATE 的血量套用到 currentMonsters。
  void _syncMonsterHp() {
    final u = gameWorldService?.hpUpdateNotifier.value;
    if (u == null) return;
    final m = currentMonsters[u.objId];
    if (m == null) return;
    currentMonsters[u.objId] =
        m.copyWith(currentHp: u.currentHp);
    // 用封包帶的 maxHp —— 波次每過一波會加血，本地那份是舊的
    worldScene?.setMonsterHp(u.objId, u.currentHp, u.maxHp);
  }

  /// 怪物的攻擊／受傷演出（S_ATTACK 是全場廣播，誰打誰都會收到）。
  ///
  /// 死亡不在這裡：最後一擊的 S_ATTACK 比血量歸零早到，
  /// 倒下由 S_HP_UPDATE（血量 0）觸發，屍體由 S_OBJECT_REMOVE 觸發。
  void _syncMonsterCombatAnimations() {
    final attack = gameWorldService?.attackNotifier.value;
    if (attack == null) return;
    if (currentMonsters.containsKey(attack.attackerObjId)) {
      worldScene?.playMonsterAttack(attack.attackerObjId, attack.targetObjId);
    }
    if (attack.hit && currentMonsters.containsKey(attack.targetObjId)) {
      worldScene?.playMonsterHurt(attack.targetObjId);
    }
  }

  void _syncLocalPlayerAttackAnimation() {
    final attack = gameWorldService?.attackNotifier.value;
    final self = _lastEnterGame?.objId;
    if (attack == null || self == null) return;
    if (attack.attackerObjId == self) worldScene?.playLocalPlayerAttack();
    if (attack.hit && attack.targetObjId == self) worldScene?.playLocalPlayerHurt();
  }

  void _syncLocalPlayerHpAnimation() {
    final update = gameWorldService?.hpUpdateNotifier.value;
    final self = _lastEnterGame?.objId;
    if (update == null || self == null || update.objId != self) return;
    if (update.currentHp <= 0) {
      worldScene?.playLocalPlayerDeath();
    }
  }

  void _syncLocalPlayerVitals() {
    final stats = gameWorldService?.liveStatsNotifier.value;
    if (stats == null) return;
    worldScene?.setLocalPlayerVitals(
      hp: stats.hp,
      hpMax: stats.hpMax,
      mp: stats.mp,
      mpMax: stats.mpMax,
    );
  }

  void _syncCharacterHpBar() {
    final update = gameWorldService?.hpUpdateNotifier.value;
    if (update == null) return;
    worldScene?.setCharacterHp(update.objId, update.currentHp, update.maxHp);
  }

  void _syncCharacterMpBar() {
    final update = gameWorldService?.mpUpdateNotifier.value;
    if (update == null) return;
    worldScene?.setCharacterMp(update.objId, update.currentMp, update.maxMp);
  }

  /// 查該格上的怪物 objId；沒有回 0。
  ///
  /// 只認怪物，不認 NPC 與場景物件 —— 點到採集點或商店 NPC 時應該走互動流程，
  /// 不是揮刀。血量 0 的也排除：屍體還在畫面上但不該能再打。
  int monsterObjIdAt(int x, int y) {
    for (final m in currentMonsters.values) {
      if (m.x == x && m.y == y && m.currentHp > 0) return m.objId;
    }
    return 0;
  }

  /// 場景物件是否佔用該格。與伺服器 DecorationInstance.occupies() 同式 ——
  /// 兩邊不一致的話，前端點得到的東西後端會說不存在。
  static bool _occupies(PropertyObject p, int x, int y) {
    final w = p.footprintW < 1 ? 1 : p.footprintW;
    final h = p.footprintH < 1 ? 1 : p.footprintH;
    return x <= p.x && x > p.x - w && y <= p.y && y > p.y - h;
  }

  /// 伺服器關閉通知：收到 S_SERVER_SHUTDOWN → 關閉遊戲視窗。
  void _onServerShutdown(SServerShutdown info) {
    _closeGameWindow('伺服器關閉：${info.message}');
  }

  /// 連線被伺服器關閉／異常（含 -9／崩潰）→ 關閉遊戲視窗。
  void _onConnectionLost() {
    _closeGameWindow('與伺服器連線中斷');
  }

  /// 關閉遊戲視窗（結束程序）。去重：避免「S_SERVER_SHUTDOWN + socket 關閉」重複觸發。
  bool _closing = false;
  void _closeGameWindow(String reason) {
    if (_closing) return;
    _closing = true;
    debugPrint('$reason → 關閉遊戲視窗');
    // 稍等一下讓日誌/畫面收尾，再結束程式（關閉視窗）。
    Future.delayed(const Duration(milliseconds: 300), () => exit(0));
  }

  Future<void> _activateWorld(SEnterGame enterGame, {int facing = 2}) async {
    _lastEnterGame = enterGame;
    // 出生／換圖落點：先設小地圖玩家箭頭初始位置，之後隨移動更新。
    playerMarkNotifier.value = (x: enterGame.x, y: enterGame.y, facing: facing);
    final gameSize = await _waitForGameSize();
    worldScene?.removeFromParent();
    worldScene = WorldSceneComponent(
      enterGame: enterGame,
      sessionService: sessionService,
      appearanceKey: _appearanceKeyFor(enterGame.charName),
      spawnFacing: facing,
      // 提供當前地圖傳送點給踏格觸發偵測（隨 S_MAP_INFO 更新）。
      portalsProvider: () => currentPortals,
      // 洞府布置模式：吃掉格子點擊，改成放置／移除家具。
      onTileTap: handleDecorTileTap,
      // 右鍵／長按角色 → 跳出選單（自己＝GM 選單，別人＝互動選單）。
      onTileSecondaryTap: handleCharacterSecondaryTap,
      // 點怪物 → 走近再攻擊
      monsterAt: monsterObjIdAt,
      onAttack: (objId) => gameWorldService?.attack(objId),
      // 玩家移動／轉向 → 更新小地圖玩家箭頭位置。
      onPlayerMoved: (x, y, f) =>
          playerMarkNotifier.value = (x: x, y: y, facing: f),
      // 走近採集／對話／攻擊物件 → 送出對應封包／開介面。
    )
      ..size = gameSize
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    add(worldScene!);
    // 世界比 S_MAP_INFO 晚建立時，用已快取的地圖資訊補上底圖。
    final cachedInfo = mapInfoNotifier.value;
    if (cachedInfo != null) {
      worldScene!.applyMapBackground(cachedInfo.gfxid);
    }
    // 圖磚要最先補套：它會重建整份地圖資料，之後的地形與物件才蓋得上去
    final tiles = currentTiles;
    if (tiles != null) {
      worldScene!.applyMapTiles(tiles);
    }
    // 地形碰撞可能早於世界建立就已收到，補套一次（順序在物件之前）
    if (currentTerrain.isNotEmpty) {
      worldScene!.applyTerrainCollision(currentTerrain);
    }
    // 場景物件可能早於世界建立就已收到，補畫一次
    if (currentProperties.isNotEmpty) {
      worldScene!.applyServerProperties(currentProperties.values.toList());
    }

    GameCharacter? initialCharacter;
    final chars = characterService?.cachedSummary?.characters ?? const [];
    for (final c in chars) {
      if (c.name == enterGame.charName) {
        initialCharacter = c;
        break;
      }
    }
    selfObjId = enterGame.objId;
    gameWorldService?.bindWorld(
      charName: enterGame.charName,
      charObjId: enterGame.objId,
      worldScene: worldScene!,
      initialCharacter: initialCharacter,
    );

    loadingSprite?.removeFromParent();
    loadingSprite = null;

    overlays.add('GameHud');
  }

  Future<AuthResult> authenticate(
    String user,
    String pass,
    String server,
  ) async {
    final service = authService;
    if (service == null) {
      return AuthResult(success: false, message: loc?.commServiceUninitialized ?? '通訊服務尚未初始化');
    }

    if (isAccountAuthenticated) {
      final logoutResult = await service.logout();
      if (!logoutResult.success) {
        debugPrint('重新登入前先登出失敗：${logoutResult.message}');
      }
    } else if (isLoggedIn) {
      await service.disconnect();
    }
    characterService?.clearCache();

    final serverStatus = serverListService?.findByName(server);
    if (serverStatus != null && !serverStatus.selectable) {
      final prefix = loc?.cannotLoginPrefix ?? '目前';
      final suffix = loc?.cannotLoginSuffix ?? '，無法登入';
      return AuthResult(
        success: false,
        message: '${serverStatus.name}$prefix${serverStatus.loadStatus.label}$suffix',
      );
    }

    debugPrint('Authenticating $user@$server ...');
    final result =
        await service.login(account: user, password: pass, serverName: server);
    // 保存權限等級：GM 面板的可見性依此判斷（伺服器每次仍會重驗，這裡只是介面過濾）
    accessLevelNotifier.value = result.loginResult?.accessLevel ?? 0;
    return result;
  }

  @override
  void onRemove() {
    unawaited(shutdownSession());
    super.onRemove();
  }
}
