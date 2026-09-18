import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/my_game.dart';
import 'package:xianxia_game/models/game_character.dart';
import 'package:xianxia_game/services/character_service.dart';
import 'package:xianxia_game/ui/screens/character_create.dart';
import 'package:xianxia_game/ui/screens/character_select.dart';
import 'package:xianxia_game/ui/layout/char_create/char_create_ui_assets.dart';
import 'package:xianxia_game/ui/layout/char_create/char_create_ui_spec.dart';
import 'package:xianxia_game/ui/layout/char_select/char_select_ui_spec.dart';
import 'package:xianxia_game/ui/layout/ui_asset_source_io.dart';
import 'package:xianxia_game/ui/theme/game_ui_fonts.dart';
import 'package:xianxia_game/ui/widgets/char_create/char_create_center_panel.dart';

class PreviewCharacters implements CharacterService {
  @override
  CharacterListSummary get cachedSummary => CharacterListSummary(
    characters: [
      GameCharacter.fromMap({'name': '測試女修', 'sex': 1}),
    ],
    count: 1,
    maxSlots: 4,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await CharCreateUiSpec.reload();
    await CharSelectUiSpec.reload();
    final font = FontLoader(GameUiFonts.kingHwaOldSong)
      ..addFont(rootBundle.load(GameUiFonts.kingHwaOldSongAsset));
    await font.load();
  });
  tearDownAll(disposeDebugAssetWatchers);
  for (final size in [
    const Size(1920, 1080),
    const Size(1280, 720),
    const Size(1920, 929),
  ]) {
    testWidgets('create and select retain opaque portraits at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = MyGame()..characterService = PreviewCharacters();
      final key = GlobalKey();
      Future<void> save(String name) async {
        await tester.pump();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final shot = await boundary.toImage();
          final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
          File(
            'docs/design/char-create-redesign/$name-${size.width.toInt()}x${size.height.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          shot.dispose();
        });
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: GameUiFonts.kingHwaOldSong),
          home: RepaintBoundary(key: key, child: CharacterCreateOverlay(game)),
        ),
      );
      await tester.runAsync(() async {
        for (final path in CharCreateUiAssets.allPreloadPaths) {
          await precacheImage(AssetImage(path), key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('女'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CharCreateCenterPanel>(find.byType(CharCreateCenterPanel))
            .sex,
        1,
      );
      expect(
        find.ancestor(
          of: find.byType(CharCreateCenterPanel),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      await save('create-female');
      await tester.tap(find.text('男'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CharCreateCenterPanel>(find.byType(CharCreateCenterPanel))
            .sex,
        0,
      );
      await save('create-male');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: GameUiFonts.kingHwaOldSong),
          home: RepaintBoundary(key: key, child: CharacterSelectOverlay(game)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CharCreateCenterPanel>(find.byType(CharCreateCenterPanel))
            .sex,
        1,
      );
      await save('select-female');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
