import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/my_game.dart';
import 'package:xianxia_game/ui/screens/game_hud_overlay.dart';

/// HUD 的版面約束。
///
/// 這支測試存在的理由：曾經因為在頂層 `Stack` 裡放了一個**非 Positioned**
/// 的子元件，整個 HUD 塌陷成 0×0、畫面上什麼都不剩，而 `flutter analyze`
/// 與當時全部 111 個測試都沒抓到 —— 因為沒有任何一個測試真的把 HUD 畫出來。
///
/// Flutter `RenderStack` 的尺寸規則有分歧：
///   - 沒有非 Positioned 子元件 → size = constraints.biggest（撐滿）
///   - 有非 Positioned 子元件   → size = max(constraints.smallest, 最大子元件)
///
/// 而 Flame 把 overlay 當作**非 Positioned 子元件**放進自己的 Stack
/// （flame/lib/src/game/game_widget/game_widget.dart 的 `Stack(children: stackedWidgets)`），
/// 所以 HUD 收到的是**寬鬆約束**（min 為 0）。兩者相乘的結果就是：
/// 只要往 HUD 頂層 Stack 加一個 0×0 的裸元件，整個 HUD 就會消失。
void main() {
  /// 刻意模擬 Flame 的擺法：HUD 是外層 Stack 的非 Positioned 子元件，
  /// 因此拿到的是寬鬆約束。用 Positioned.fill 包住就測不到這個 bug 了。
  Future<void> pumpHudLikeFlame(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [GameHudOverlay(MyGame())],
        ),
      ),
    );
    await tester.pump();
  }

  /// HUD 內部那個頂層 Stack（`GameHudOverlay` 底下的第一個 Stack）。
  Size hudStackSize(WidgetTester tester) {
    final stack = find.descendant(
      of: find.byType(GameHudOverlay),
      matching: find.byType(Stack),
    );
    return tester.getSize(stack.first);
  }

  testWidgets('桌面尺寸：HUD 撐滿可用空間，不會塌陷成 0×0', (tester) async {
    await pumpHudLikeFlame(tester, const Size(1920, 1080));

    final size = hudStackSize(tester);
    expect(size.width, greaterThan(0),
        reason: 'HUD 塌陷了 —— 頂層 Stack 裡出現了非 Positioned 的子元件');
    expect(size.height, greaterThan(0),
        reason: 'HUD 塌陷了 —— 頂層 Stack 裡出現了非 Positioned 的子元件');
    // 撐滿而非只有某個子元件那麼大
    expect(size.width, 1920);
  });

  testWidgets('手機橫向 952x426：同樣撐滿，不被裁切', (tester) async {
    await pumpHudLikeFlame(tester, const Size(952, 426));

    final size = hudStackSize(tester);
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
    expect(size.width, 952);
  });

  testWidgets('HUD 建構過程不拋例外', (tester) async {
    await pumpHudLikeFlame(tester, const Size(1280, 720));
    expect(tester.takeException(), isNull);
  });
}
