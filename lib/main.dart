import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'config/app_config.dart';
import 'game/my_game.dart';
import 'ui/screens/loading_overlay.dart';
import 'ui/screens/transition_overlay.dart';
import 'ui/screens/account.dart';
import 'ui/screens/character_create.dart';
import 'ui/screens/character_select.dart';
import 'ui/screens/serverlist.dart';
import 'ui/screens/game_hud_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 早載入 App 設定（含 log 開關），全程可同步讀取 AppConfigLoader.current。
  await AppConfigLoader.load();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final MyGame _myGame;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _myGame = MyGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_myGame.shutdownSession());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }
          unawaited(_myGame.exitApplication());
        },
        child: GameWidget(
          game: _myGame,
          overlayBuilderMap: {
            'Loading': (context, game) => LoadingOverlay(game as MyGame),
            'Transition': (context, game) => TransitionOverlay(game as MyGame),
            'Account': (context, game) => AccountOverlay(game as MyGame),
            'ServerSelect': (context, game) =>
                ServerSelectOverlay(game as MyGame),
            'CharacterCreate': (context, game) =>
                CharacterCreateOverlay(game as MyGame),
            'CharacterSelect': (context, game) =>
                CharacterSelectOverlay(game as MyGame),
            'GameHud': (context, game) => GameHudOverlay(game as MyGame),
          },
          initialActiveOverlays: const ['Loading'],
        ),
      ),
    );
  }
}
