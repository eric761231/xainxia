import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/ui/layout/xaml/specs/loading_ui_spec.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_assets.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_loader.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_node.dart';
import 'package:xianxia_game/ui/layout/xaml/ui_xaml_registry.dart';
import 'package:xianxia_game/ui/widgets/shared/energy_loading_bar.dart';
import 'package:xianxia_game/ui/widgets/shared/progress_overlay_scaffold.dart';
import 'package:xml/xml.dart';

LoadingUiSpec _specFrom(String xaml,
    {Map<String, String> tokens = const {},
    Map<String, String> assets = const {}}) {
  final root = XmlDocument.parse(xaml).rootElement;
  final node = UiXamlNode.parse(root, tokens: tokens, isRoot: true)!;
  final document = UiXamlDocument(
    id: 'loading',
    designWidth: 1920,
    designHeight: 1080,
    root: node,
    source: 'test',
  );
  return LoadingUiSpec.fromResultForTest(
    UiXamlResult(
      tier: UiXamlTier.xaml,
      view: UiXamlRegistry.loading,
      document: document,
    ),
    UiXamlAssets(paths: assets),
  );
}

Future<void> _pumpBar(
  WidgetTester tester, {
  required double progress,
  required LoadingUiSpec spec,
  Size size = const Size(1920, 1080),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ProgressOverlayScaffold(
        progress: ValueNotifier<double>(progress),
        spec: spec,
      ),
    ),
  );
  // 進度條的紋理動畫是 repeat()，永遠不會 settle —— 用固定時間 pump。
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoadingUiSpec', () {
    test('沒有 document 時整份退回 Dart 預設', () {
      final spec = LoadingUiSpec.fromResultForTest(
        const UiXamlResult(
          tier: UiXamlTier.dartDefault,
          view: UiXamlRegistry.loading,
        ),
        UiXamlAssets.fallback,
      );
      expect(spec.barHeight, LoadingUiSpec.defaults.barHeight);
      expect(spec.backgroundAsset, LoadingUiSpec.defaults.backgroundAsset);
    });

    test('bar 高度夾在 30–36', () {
      expect(
        _specFrom('<UiView><ProgressBar id="progress" height="3200" /></UiView>')
            .barHeight,
        36,
      );
      expect(
        _specFrom('<UiView><ProgressBar id="progress" height="4" /></UiView>')
            .barHeight,
        30,
      );
    });

    test('asset id 透過 manifest 解析；未登記時退回 Dart 預設路徑', () {
      final spec = _specFrom(
        '<UiView><Background asset="loginFlowBg" /></UiView>',
        assets: const {'loginFlowBg': 'assets/ui/login_flow/login_flow_bg.png'},
      );
      expect(spec.backgroundAsset, 'assets/ui/login_flow/login_flow_bg.png');

      final missing =
          _specFrom('<UiView><Background asset="nope" /></UiView>');
      expect(missing.backgroundAsset, LoadingUiSpec.defaults.backgroundAsset);
    });

    test('theme token 可用於尺寸', () {
      final spec = _specFrom(
        '<UiView><ProgressBar id="progress" height="{loadingBarHeight}" /></UiView>',
        tokens: const {'loadingBarHeight': '34'},
      );
      expect(spec.barHeight, 34);
    });

    test('實際的 loading.xaml 能載入且合乎規格', () async {
      UiXamlLoader.resetForTest();
      await LoadingUiSpec.holder.reload();
      final spec = LoadingUiSpec.current;
      expect(LoadingUiSpec.holder.tier, UiXamlTier.xaml);
      expect(spec.barHeight, inInclusiveRange(30, 36));
      expect(spec.backgroundAsset, contains('login_flow'));
      expect(spec.textureAsset, contains('loading_energy'));
      expect(spec.showLabel, isTrue, reason: '百分比必須由 Flutter 顯示，不烘進 PNG');
    });
  });

  group('進度條裁切與百分比', () {
    const spec = LoadingUiSpec(textureAsset: null);

    for (final percent in [0, 1, 50, 99, 100]) {
      testWidgets('$percent% 的填充寬度與文字都正確', (tester) async {
        await _pumpBar(tester, progress: percent / 100, spec: spec);

        expect(find.text('$percent%'), findsOneWidget);

        final fill = tester.widget<FractionallySizedBox>(
          find.descendant(
            of: find.byType(EnergyLoadingBar),
            matching: find.byType(FractionallySizedBox),
          ),
        );
        expect(fill.widthFactor, closeTo(percent / 100, 1e-9));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('超出 0–1 的進度被夾住，不會畫出界', (tester) async {
      await _pumpBar(tester, progress: 1.8, spec: spec);
      expect(find.text('100%'), findsOneWidget);
      await _pumpBar(tester, progress: -0.5, spec: spec);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('百分比置中於 bar 內', (tester) async {
      await _pumpBar(tester, progress: 0.5, spec: spec);
      final bar = tester.getRect(find.byType(EnergyLoadingBar));
      final label = tester.getRect(find.text('50%'));
      expect(label.center.dx, closeTo(bar.center.dx, 1.0));
      expect(label.center.dy, closeTo(bar.center.dy, 1.0));
      expect(bar.contains(label.center), isTrue);
    });
  });

  group('各解析度不溢位', () {
    const sizes = [
      Size(1920, 1080),
      Size(1366, 768),
      Size(1280, 720),
      Size(844, 390),
    ];

    for (final size in sizes) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pumpBar(
          tester,
          progress: 0.5,
          spec: const LoadingUiSpec(textureAsset: null),
          size: size,
        );
        expect(tester.takeException(), isNull);

        final bar = tester.getRect(find.byType(EnergyLoadingBar));
        expect(bar.width, lessThanOrEqualTo(size.width + 0.5),
            reason: '進度條不可寬過畫面');
        expect(bar.height, greaterThan(0));
      });
    }
  });

  group('過場訊息覆寫', () {
    testWidgets('有覆寫時顯示覆寫值，空字串則退回 XAML 的文字', (tester) async {
      final message = ValueNotifier<String>('前往黑森林');
      await tester.pumpWidget(
        MaterialApp(
          home: ProgressOverlayScaffold(
            progress: ValueNotifier<double>(0.3),
            messageOverride: message,
            spec: const LoadingUiSpec(textureAsset: null),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('前往黑森林'), findsOneWidget);

      message.value = '';
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text(LoadingUiSpec.defaults.messageText), findsOneWidget);
    });
  });
}
