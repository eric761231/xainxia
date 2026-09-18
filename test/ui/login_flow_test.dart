import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/my_game.dart';
import 'package:xianxia_game/models/server_status.dart';
import 'package:xianxia_game/ui/screens/account.dart';
import 'package:xianxia_game/ui/screens/serverlist.dart';
import 'package:xianxia_game/ui/widgets/shared/ink_fade_rect.dart';

void main() {
  for (final size in [
    const Size(1280, 720),
    const Size(684, 483),
    const Size(360, 640),
  ]) {
    testWidgets(
      'server selection keeps credentials and never overlaps at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = MyGame();
        game.serverStatuses = [
          for (final name in ['東勝神州', '南贍部州', '維修伺服器'])
            ServerStatus(
              id: name,
              name: name,
              host: 'localhost',
              port: 0,
              loadStatus: name == '維修伺服器'
                  ? ServerLoadStatus.maintenance
                  : ServerLoadStatus.smooth,
            ),
        ];
        await tester.pumpWidget(MaterialApp(home: AccountOverlay(game)));
        await tester.enterText(
          find.byKey(const ValueKey('login-account')),
          'testuser',
        );
        await tester.enterText(
          find.byKey(const ValueKey('login-password')),
          'testpass',
        );
        expect(find.text('等待輸入'), findsNothing);
        final accountBefore = tester.getRect(
          find.byKey(const ValueKey('login-account')),
        );
        if (size.width >= 900) {
          await tester.tap(find.byTooltip('展開伺服器列表'));
        } else {
          await tester.tap(find.textContaining('伺服器列表'));
        }
        await tester.pumpAndSettle();
        expect(find.text('帳號登入'), findsNothing);
        expect(find.byType(InkFadeRect), findsNothing);
        expect(game.overlays.isActive('ServerSelect'), isFalse);
        if (size.width >= 900) {
          final form = tester.getRect(
            find.byKey(const ValueKey('login-account')),
          );
          final panel = tester.getRect(find.byType(ServerSelectOverlay));
          expect(form, accountBefore);
          expect(form.overlaps(panel), isFalse);
          expect(panel.left, greaterThan(form.right));
        }
        await tester.tap(find.text('維修伺服器'));
        await tester.pump();
        expect(find.text('✓ 東勝神州'), findsNothing);
        expect(find.text('東勝神州'), findsOneWidget);
        await tester.tap(find.text('南贍部州'));
        await tester.pump();
        await tester.tap(find.text('確認'));
        await tester.pumpAndSettle();
        expect(game.selectedServer, '南贍部州');
        expect(find.byType(ServerSelectOverlay), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('login-account')))
              .controller!
              .text,
          'testuser',
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('login-password')))
              .controller!
              .text,
          'testpass',
        );
        if (size.width >= 900) {
          await tester.tap(find.byTooltip('展開伺服器列表'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('收合伺服器選單'));
        } else {
          await tester.tap(find.textContaining('伺服器列表'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('收合伺服器列表'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ServerSelectOverlay), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
