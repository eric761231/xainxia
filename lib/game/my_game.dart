import 'dart:async';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xianxia_game/l10n/app_localizations.dart';

import '../ui/layout/char_create/char_create_ui_preloader.dart';
import '../config/server_connection_loader.dart';
import '../models/server_status.dart';
import '../models/game_character.dart';
import '../network/packets/server/s_enter_game.dart';
import '../network/packets/server/s_map_change.dart';
import '../network/packets/server/s_map_info.dart';
import '../network/packets/server/s_server_shutdown.dart';
import '../services/auth_service.dart';
import '../services/character_service.dart';
import '../services/game_session_service.dart';
import '../services/game_world_service.dart';
import '../services/server_list_service.dart';
import 'world_scene.dart';

class MyGame extends FlameGame {
  double progress = 0.0;
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

  /// 當前地圖的傳送點清單（供 WorldScene 踏格觸發偵測）。
  List<PortalPoint> currentPortals = const [];

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
    sessionService!.dispatcher.onServerShutdown = _onServerShutdown;
    // 連線被伺服器關閉／異常（含 -9／崩潰）→ 關閉遊戲視窗。
    sessionService!.onConnectionLost = _onConnectionLost;
    authService = AuthService(connectionConfig!, sessionService!);
    characterService = CharacterService(sessionService!, connectionConfig!);
    gameWorldService = GameWorldService(sessionService!);
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

    progress = 0.5;
    progressNotifier.value = progress;
    await Future.delayed(const Duration(milliseconds: 600));
    progress = 1.0;
    progressNotifier.value = progress;
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

    await runTransition(
      message: loc?.enteringCharacterUI ?? '進入角色介面…',
      loadTask: (report) => CharCreateUiPreloader.preload(onProgress: report),
    );

    final service = characterService;
    if (service == null) {
      return;
    }

    try {
      final summary = await service.fetchCharacterList();
      if (summary.characters.isEmpty) {
        showCharacterCreate();
      } else {
        showCharacterSelect();
      }
    } catch (e) {
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
    }
  }

  /// 離開 App：顯示關閉過場畫面 → 登出 → 關閉。
  /// 過場畫面保持到程式結束（不移除），避免關閉前閃回底層畫面。
  Future<void> exitApplication() async {
    transitionMessageNotifier.value = loc?.closingGame ?? '正在關閉遊戲…';
    progress = 0;
    progressNotifier.value = 0;
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
      // 玩家移動／轉向 → 更新小地圖玩家箭頭位置。
      onPlayerMoved: (x, y, f) =>
          playerMarkNotifier.value = (x: x, y: y, facing: f),
      // 走近採集／對話／攻擊物件 → 送出對應封包／開介面。
      onInteract: (it) => gameWorldService?.handleInteract(it),
    )
      ..size = gameSize
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    add(worldScene!);

    GameCharacter? initialCharacter;
    final chars = characterService?.cachedSummary?.characters ?? const [];
    for (final c in chars) {
      if (c.name == enterGame.charName) {
        initialCharacter = c;
        break;
      }
    }
    gameWorldService?.bindWorld(
      charName: enterGame.charName,
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
    return service.login(account: user, password: pass, serverName: server);
  }

  @override
  void onRemove() {
    unawaited(shutdownSession());
    super.onRemove();
  }
}
