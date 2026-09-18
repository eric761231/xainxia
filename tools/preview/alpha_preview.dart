// Offline visual fixture: real screens and assets, no network or authentication.
import 'package:flutter/material.dart';
import 'package:xianxia_game/game/my_game.dart';
import 'package:xianxia_game/models/game_character.dart';
import 'package:xianxia_game/services/character_service.dart';
import 'package:xianxia_game/ui/screens/character_create.dart';
import 'package:xianxia_game/ui/screens/character_select.dart';
import 'package:xianxia_game/ui/layout/char_create/char_create_ui_spec.dart';
import 'package:xianxia_game/ui/layout/char_select/char_select_ui_spec.dart';

class PreviewCharacters implements CharacterService {
  @override
  CharacterListSummary get cachedSummary => CharacterListSummary(
    characters: [
      GameCharacter.fromMap({'name': '女修透明度驗收', 'sex': 1}),
      GameCharacter.fromMap({'name': '男修透明度驗收', 'sex': 0}),
    ],
    count: 2,
    maxSlots: 4,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Offline visual preview');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CharCreateUiSpec.reload();
  await CharSelectUiSpec.reload();
  runApp(const AlphaPreview());
}

class AlphaPreview extends StatefulWidget {
  const AlphaPreview({super.key});
  @override
  State<AlphaPreview> createState() => _AlphaPreviewState();
}

class _AlphaPreviewState extends State<AlphaPreview> {
  final game = MyGame()..characterService = PreviewCharacters();
  bool select = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                const Text('離線素材驗收 · 不連線'),
                TextButton(
                  onPressed: () => setState(() => select = false),
                  child: const Text('創角'),
                ),
                TextButton(
                  onPressed: () => setState(() => select = true),
                  child: const Text('選角'),
                ),
              ],
            ),
          ),
          Expanded(
            child: select
                ? CharacterSelectOverlay(game)
                : CharacterCreateOverlay(game),
          ),
        ],
      ),
    ),
  );
}
