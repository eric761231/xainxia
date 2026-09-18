import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_assets.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_loader.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_node.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_registry.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_theme.dart';
import 'package:xml/xml.dart';

UiXamlNode _parse(String xml,
    {Map<String, String> tokens = const {}, UiXamlDiagnostics? diagnostics}) {
  final root = XmlDocument.parse(xml).rootElement;
  return UiXamlNode.parse(root,
      tokens: tokens, diagnostics: diagnostics, isRoot: true)!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UiXamlNode：白名單與寬容解析', () {
    test('未知節點被忽略並記警告，不影響其餘節點', () {
      final d = UiXamlDiagnostics();
      final node = _parse('''
        <UiView>
          <Text id="ok" />
          <WebView id="危險" />
          <Image id="also" />
        </UiView>
      ''', diagnostics: d);

      expect(node.children.map((n) => n.type), ['Text', 'Image']);
      expect(node.findById('危險'), isNull);
      expect(d.messages.single, contains('WebView'));
    });

    test('巢狀結構內的未知節點同樣被濾掉', () {
      final node = _parse('''
        <UiView><Stack><Script /><Text id="deep" /></Stack></UiView>
      ''');
      expect(node.findById('deep'), isNotNull);
      expect(node.child('Stack')!.children.map((n) => n.type), ['Text']);
    });
  });

  group('UiXamlNode：型別安全取值', () {
    test('數值超出 min/max 會被夾住並記警告', () {
      final d = UiXamlDiagnostics();
      final node = _parse('<UiView><ProgressBar height="3200" /></UiView>',
          diagnostics: d);
      final bar = node.child('ProgressBar')!;

      expect(bar.d('height', 32, min: 30, max: 36), 36);
      expect(d.messages.single, contains('夾成'));
    });

    test('非數字退回 fallback，且 fallback 本身也會被夾住', () {
      final node = _parse('<UiView><ProgressBar height="很高" /></UiView>');
      final bar = node.child('ProgressBar')!;
      expect(bar.d('height', 999, min: 30, max: 36), 36);
    });

    test('缺屬性回 fallback', () {
      final node = _parse('<UiView><Text /></UiView>');
      expect(node.child('Text')!.d('size', 18), 18);
      expect(node.child('Text')!.s('label', '預設'), '預設');
      expect(node.child('Text')!.b('visible', true), isTrue);
    });

    test('bool 接受 true/false/1/0，其餘退回 fallback', () {
      final node = _parse(
          '<UiView><Text a="true" b="0" c="yes" /></UiView>');
      final t = node.child('Text')!;
      expect(t.b('a', false), isTrue);
      expect(t.b('b', true), isFalse);
      expect(t.b('c', true), isTrue, reason: '無法解析時保留 fallback');
    });

    test('顏色：8 碼含 alpha、6 碼補不透明、可省略 #', () {
      final node = _parse(
          '<UiView><Text a="#80FF0000" b="00FF00" c="不是顏色" /></UiView>');
      final t = node.child('Text')!;
      expect(t.color('a', Colors.black), const Color(0x80FF0000));
      expect(t.color('b', Colors.black), const Color(0xFF00FF00));
      expect(t.color('c', Colors.black), Colors.black);
    });

    test('int 由 double 四捨五入而來，同樣吃 clamp', () {
      final node = _parse('<UiView><List count="4.6" /></UiView>');
      expect(node.child('List')!.i('count', 1), 5);
      expect(node.child('List')!.i('count', 1, max: 3), 3);
    });
  });

  group('UiXamlNode：theme token 參照', () {
    test('{token} 會被展開', () {
      final node = _parse(
        '<UiView><TextField id="a" width="{fieldWidth}" /></UiView>',
        tokens: const {'fieldWidth': '390'},
      );
      expect(node.findById('a')!.d('width', 0), 390);
    });

    test('帳號與密碼引用同一 token 必然等寬', () {
      final node = _parse('''
        <UiView>
          <TextField id="account" width="{fieldWidth}" />
          <TextField id="password" width="{fieldWidth}" />
        </UiView>
      ''', tokens: const {'fieldWidth': '390'});

      expect(node.findById('account')!.d('width', 0),
          node.findById('password')!.d('width', 0));
    });

    test('不存在的 token 退回 fallback 並記警告', () {
      final d = UiXamlDiagnostics();
      final node = _parse('<UiView><TextField width="{nope}" /></UiView>',
          diagnostics: d);
      expect(node.child('TextField')!.d('width', 120), 120);
      expect(d.messages.single, contains('token'));
    });
  });

  group('UiXamlTheme', () {
    test('解析 token 並依型別取值', () {
      final theme = UiXamlTheme.parse('''
        <Theme>
          <Color id="ink" value="#0E0F12" />
          <Size id="fieldWidth" value="390" />
        </Theme>
      ''');
      expect(theme.size('fieldWidth', 0), 390);
      expect(theme.color('ink', Colors.white), const Color(0xFF0E0F12));
      expect(theme.size('missing', 7), 7);
    });

    test('壞掉的 XML 整份退回 fallback，不丟例外', () {
      final d = UiXamlDiagnostics();
      final theme = UiXamlTheme.parse('<Theme><Color', diagnostics: d);
      expect(theme.isEmpty, isTrue);
      expect(d.messages.single, contains('解析失敗'));
    });

    test('缺 id/value 的節點被忽略；重複 id 取後者並記警告', () {
      final d = UiXamlDiagnostics();
      final theme = UiXamlTheme.parse('''
        <Theme>
          <Size id="a" value="1" />
          <Size value="2" />
          <Size id="a" value="3" />
        </Theme>
      ''', diagnostics: d);
      expect(theme.size('a', 0), 3);
      expect(d.messages.length, 2);
    });
  });

  group('UiXamlAssets', () {
    test('id 對到路徑；未登記回 fallbackPath', () {
      final assets = UiXamlAssets.parse(
        '<UiAssets><Asset id="bg" path="assets/a.png" /></UiAssets>',
      );
      expect(assets.path('bg'), 'assets/a.png');
      expect(assets.path('nope'), isNull);
      expect(assets.path('nope', fallbackPath: 'assets/old.png'),
          'assets/old.png');
    });

    test('非 Asset 節點與缺欄位都被忽略並記警告', () {
      final d = UiXamlDiagnostics();
      final assets = UiXamlAssets.parse('''
        <UiAssets>
          <Asset id="ok" path="assets/a.png" />
          <Folder id="x" path="y" />
          <Asset id="缺路徑" />
        </UiAssets>
      ''', diagnostics: d);
      expect(assets.paths.keys, ['ok']);
      expect(d.messages.length, 2);
    });
  });

  group('UiXamlLoader：三段式 fallback', () {
    setUp(UiXamlLoader.resetForTest);

    test('theme 與 assets 由實際檔案載入', () async {
      await UiXamlLoader.ensureShared();
      expect(UiXamlLoader.sharedLoaded, isTrue);
      expect(UiXamlLoader.theme.size('fieldWidth', -1), greaterThan(0),
          reason: 'theme.xaml 必須提供 fieldWidth，兩個輸入欄靠它等寬');
      expect(UiXamlLoader.assets.path('loginFlowBg'), isNotNull);
      expect(UiXamlLoader.assets.path('loadingEnergy'), isNotNull);
      expect(UiXamlLoader.assets.path('loginFailedIcon'), isNotNull);
      expect(UiXamlLoader.assets.path('connectionLostIcon'), isNotNull);
    });

    test('沒有 .xaml 也沒有舊 .xml → dartDefault', () async {
      final result = await UiXamlLoader.load(UiXamlRegistry.gameHud);
      expect(result.tier, UiXamlTier.dartDefault);
      expect(result.document, isNull);
      expect(result.legacyXml, isNull);
    });

    test('沒有 .xaml 但有舊 .xml → legacyXml，並帶回原始字串', () async {
      final result = await UiXamlLoader.load(UiXamlRegistry.characterSelect);
      expect(result.tier, UiXamlTier.legacyXml);
      expect(result.legacyXml, isNotNull);
      expect(result.legacyXml, contains('<'));
    });

    test('registry 的監看清單涵蓋 theme、assets 與每個畫面的新舊檔', () {
      final paths = UiXamlRegistry.watchPaths;
      expect(paths, contains(UiXamlRegistry.theme));
      expect(paths, contains(UiXamlRegistry.assets));
      for (final view in UiXamlRegistry.views) {
        expect(paths, contains(view.xaml));
        if (view.legacyXml != null) {
          expect(paths, contains(view.legacyXml));
        }
      }
    });

    test('每個畫面 id 唯一，且 xaml 路徑不重複', () {
      final ids = UiXamlRegistry.views.map((v) => v.id).toList();
      final paths = UiXamlRegistry.views.map((v) => v.xaml).toList();
      expect(ids.toSet().length, ids.length);
      expect(paths.toSet().length, paths.length);
    });
  });
}
