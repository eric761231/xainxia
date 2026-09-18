import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/ui/layout/xaml/specs/account_ui_spec.dart';
import 'package:xianxia_game/ui/layout/xaml/specs/server_select_ui_spec.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_assets.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_loader.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_node.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_registry.dart';
import 'package:xianxia_game/ui/widgets/shared/ink_fade_rect.dart';
import 'package:xml/xml.dart';

UiXamlResult _result(
  String xaml,
  UiXamlView view, {
  Map<String, String> tokens = const {},
}) {
  final root = XmlDocument.parse(xaml).rootElement;
  final node = UiXamlNode.parse(root, tokens: tokens, isRoot: true)!;
  return UiXamlResult(
    tier: UiXamlTier.xaml,
    view: view,
    document: UiXamlDocument(
      id: view.id,
      designWidth: 1920,
      designHeight: 1080,
      root: node,
      source: 'test',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountUiSpec', () {
    test('沒有 document 時退回 Dart 預設', () {
      final spec = AccountUiSpec.fromResultForTest(
        const UiXamlResult(
          tier: UiXamlTier.dartDefault,
          view: UiXamlRegistry.account,
        ),
        UiXamlAssets.fallback,
      );
      expect(spec.account.box.width, AccountUiSpec.defaults.account.box.width);
    });

    test('帳號與密碼引用同一 token → 等寬且左右端點對齊', () {
      final spec = AccountUiSpec.fromResultForTest(
        _result(
          '''
          <UiView id="account">
            <TextField id="account" centerX="960" width="{fieldWidth}" />
            <TextField id="password" centerX="960" width="{fieldWidth}" />
          </UiView>
        ''',
          UiXamlRegistry.account,
          tokens: const {'fieldWidth': '420'},
        ),
        UiXamlAssets.fallback,
      );
      expect(spec.account.box.width, 420);
      expect(spec.password.box.width, spec.account.box.width);
      expect(spec.password.box.centerX, spec.account.box.centerX);
    });

    test('實際的 account.xaml：兩欄等寬、登入區透明且不顯示標題', () async {
      UiXamlLoader.resetForTest();
      await AccountUiSpec.holder.reload();
      final spec = AccountUiSpec.current;

      expect(AccountUiSpec.holder.tier, UiXamlTier.xaml);
      expect(
        spec.account.box.width,
        spec.password.box.width,
        reason: '帳號與密碼必須等寬',
      );
      expect(
        spec.account.box.centerX,
        spec.password.box.centerX,
        reason: '左右端點必須對齊',
      );
      expect(spec.loginArea.fadeX, greaterThan(0));
      expect(spec.loginArea.fadeY, greaterThan(0), reason: '四邊都要淡出，不是單向漸層');
      expect(spec.loginArea.centerOpacity, 0);
      expect(spec.title.text, isEmpty);
      expect(spec.backgroundAsset, contains('login_flow'));
    });

    test('畫面 id 與節點 id 是兩個命名空間，根節點不會被 findById 命中', () {
      final spec = AccountUiSpec.fromResultForTest(
        _result(
          '''
          <UiView id="account">
            <TextField id="account" width="{fieldWidth}" />
          </UiView>
        ''',
          UiXamlRegistry.account,
          tokens: const {'fieldWidth': '512'},
        ),
        UiXamlAssets.fallback,
      );
      expect(
        spec.account.box.width,
        512,
        reason: 'id="account" 的欄位不可被同名的 UiView 根節點蓋掉',
      );
    });

    test('實際的 account.xaml 沒有寫非 0 的 radius', () async {
      final raw = await UiXamlLoader.load(
        UiXamlRegistry.account,
      ).then((r) => r.document);
      final area = raw!.findById('loginArea')!;
      expect(area.raw('radius'), '0', reason: 'InkFadeRect 必須是直角');
    });
  });

  group('ServerSelectUiSpec', () {
    test('伺服器清單為緊湊單欄且不填色', () async {
      UiXamlLoader.resetForTest();
      await ServerSelectUiSpec.holder.reload();
      final grid = ServerSelectUiSpec.current.grid;

      expect(ServerSelectUiSpec.holder.tier, UiXamlTier.xaml);
      expect(grid.columns, 1);
      expect(grid.selectedLineWidth, greaterThan(0));
      expect(grid.selectedGlowOpacity, 0);
      expect(grid.disabledOpacity, lessThan(1), reason: '維護／離線要靠變暗表達不可點');
    });

    test('欄數與尺寸都吃 clamp', () {
      final spec = ServerSelectUiSpec.fromResultForTest(
        _result(
          '<UiView id="serverSelect"><List id="grid" columns="99" itemHeight="2" /></UiView>',
          UiXamlRegistry.serverSelect,
        ),
        UiXamlAssets.fallback,
      );
      expect(spec.grid.columns, 6);
      expect(spec.grid.itemHeight, 24);
    });

    test('取消與確認是兩個不同位置的按鈕', () async {
      final spec = ServerSelectUiSpec.current;
      expect(spec.cancel.text, '取消');
      expect(spec.confirm.text, '確認');
      expect(spec.cancel.box.centerX, isNot(spec.confirm.box.centerX));
    });
  });

  group('InkFadeRect', () {
    testWidgets('是直角矩形：沒有 ClipRRect、沒有 Border、沒有圓角', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: InkFadeRect(width: 620, height: 620, fadeX: 120, fadeY: 100),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);

      for (final box in tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox, skipOffstage: false),
      )) {
        final decoration = box.decoration;
        if (decoration is BoxDecoration) {
          expect(decoration.borderRadius, isNull);
          expect(decoration.border, isNull);
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('水平與垂直各有一層淡出遮罩（四邊都淡出）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: InkFadeRect(width: 400, height: 300, fadeX: 80, fadeY: 60),
          ),
        ),
      );
      expect(find.byType(ShaderMask), findsNWidgets(2));
    });

    testWidgets('淡出距離超過一半時會被夾住，中央仍保有平台', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: InkFadeRect(
              width: 200,
              height: 200,
              fadeX: 9999,
              fadeY: 9999,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ShaderMask), findsNWidgets(2));
    });

    testWidgets('fade 為 0 時不套遮罩，直接是純色塊', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: InkFadeRect(width: 200, height: 200, fadeX: 0, fadeY: 0),
          ),
        ),
      );
      expect(find.byType(ShaderMask), findsNothing);
    });
  });
}
