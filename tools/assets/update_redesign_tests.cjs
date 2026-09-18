const fs=require('node:fs');
let p='test/ui/asset_alpha_test.dart',s=fs.readFileSync(p,'utf8');
s=s.replace('File(CharCreateUiAssets.charFemale).readAsBytesSync()',"File('docs/design/char-create-redesign/before/char_female.png').readAsBytesSync()");
s=s.replace('File(CharCreateUiAssets.charMale).readAsBytesSync()',"File('docs/design/char-create-redesign/before/char_male.png').readAsBytesSync()");
fs.writeFileSync(p,s);
p='test/ui/portrait_render_test.dart';s=fs.readFileSync(p,'utf8').replace("'docs/alpha/$name-", "'docs/design/char-create-redesign/$name-");s=s.replace("await tester.tap(find.text('男'));", "await tester.tap(find.text('男'));");s=s.replace("      await tester.pumpWidget(\n        MaterialApp(\n          theme: ThemeData(fontFamily: GameUiFonts.kingHwaOldSong),\n          home: RepaintBoundary(key: key, child: CharacterSelectOverlay(game)),", "      await save('create-male');\n      await tester.pumpWidget(\n        MaterialApp(\n          theme: ThemeData(fontFamily: GameUiFonts.kingHwaOldSong),\n          home: RepaintBoundary(key: key, child: CharacterSelectOverlay(game)),");fs.writeFileSync(p,s);
