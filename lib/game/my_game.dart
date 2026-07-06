import 'dart:async';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/layout/char_create/char_create_ui_preloader.dart';
import '../config/server_connection_loader.dart';
import '../models/server_status.dart';
import '../models/game_character.dart';
import '../network/packets/server/s_enter_game.dart';
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
    debugPrint('警告：無法取得有效 game size，使用預設 1280×720');
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
      message: '進入角色介面…',
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
      debugPrint('查詢角色列表失敗：$e');
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
    transitionMessageNotifier.value = '正在關閉遊戲…';
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
      return const CharacterResult(success: false, message: '角色服務尚未初始化');
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
      return const CharacterResult(success: false, message: '角色服務尚未初始化');
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
      throw StateError('角色服務尚未初始化');
    }

    overlays.remove('CharacterSelect');
    overlays.remove('CharacterCreate');

    await runTransition(message: '進入世界…', assetPaths: _mapAssets);

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

  Future<void> _activateWorld(SEnterGame enterGame) async {
    final gameSize = await _waitForGameSize();
    worldScene?.removeFromParent();
    worldScene = WorldSceneComponent(
      enterGame: enterGame,
      sessionService: sessionService,
      appearanceKey: _appearanceKeyFor(enterGame.charName),
      // 本地切換地圖：踏到出口 → 以同角色合成 SEnterGame 重新進場。
      onRequestMapChange: (toMap, toX, toY) => _activateWorld(SEnterGame(
        objId: enterGame.objId,
        charName: enterGame.charName,
        mapId: toMap,
        x: toX,
        y: toY,
      )),
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
      return const AuthResult(success: false, message: '通訊服務尚未初始化');
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
      return AuthResult(
        success: false,
        message: '${serverStatus.name}目前${serverStatus.loadStatus.label}，無法登入',
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
