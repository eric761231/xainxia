import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/ui/widgets/shared/notched_bar.dart';

const hpRed = Color(0xFFC0392B);
const mpBlue = Color(0xFF2E6FC0);

/// 把單一元件實際畫成點陣圖，回傳取樣函式。
///
/// 只驗形狀常數是不夠的 —— 條有沒有真的填上顏色，得看畫出來的像素。
Future<Color Function(int x, int y)> render(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Row(children: [Expanded(child: child)]),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // toImage() 要等引擎的 raster 執行緒真的畫完，而 testWidgets 跑在假時鐘上，
  // 假時鐘不會推進真實的非同步工作 —— 不包 runAsync 的話這個 Future 永遠不
  // 會完成，整支測試會卡到逾時（實測每個案例卡滿 10 分鐘）。
  // pumpWidget／pumpAndSettle 必須留在外面：它們反過來依賴假時鐘。
  late Uint8List bytes;
  late int w;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    bytes = data!.buffer.asUint8List();
    w = image.width;
    image.dispose();
  });

  return (int x, int y) {
    final i = (y * w + x) * 4;
    return Color.fromARGB(
        bytes[i + 3], bytes[i], bytes[i + 1], bytes[i + 2]);
  };
}

/// 兩色是否接近（避免抗鋸齒造成的微小差異）。
bool near(Color a, Color b, {int tol = 12}) =>
    (a.r * 255 - b.r * 255).abs() <= tol &&
    (a.g * 255 - b.g * 255).abs() <= tol &&
    (a.b * 255 - b.b * 255).abs() <= tol;

void main() {
  group('HP 條（凹口在右）', () {
    testWidgets('填充區實際畫出紅色', (tester) async {
      final at = await render(
        tester,
        const NotchedBar(
            fraction: 0.6,
            color: hpRed,
            height: 60,
            notch: 30,
            notchOnRight: true),
        size: const Size(200, 60),
      );
      // 左端在填充範圍內（0.6 × 200 = 120）
      expect(near(at(10, 30), hpRed), isTrue,
          reason: '左端應為紅色，實得 ${at(10, 30)}');
      expect(near(at(100, 30), hpRed), isTrue,
          reason: '填充範圍內應為紅色，實得 ${at(100, 30)}');
    });

    testWidgets('未填充區是底槽色，不是紅色', (tester) async {
      final at = await render(
        tester,
        const NotchedBar(
            fraction: 0.3,
            color: hpRed,
            height: 60,
            notch: 30,
            notchOnRight: true),
        size: const Size(200, 60),
      );
      // 0.3 × 200 = 60，x=100 已超出填充
      expect(near(at(100, 30), hpRed), isFalse,
          reason: '超出填充範圍不該是紅色，實得 ${at(100, 30)}');
    });

    testWidgets('右端的 V 形凹口確實被切掉（該處露出背景）', (tester) async {
      final at = await render(
        tester,
        const NotchedBar(
            fraction: 1.0,
            color: hpRed,
            height: 60,
            notch: 30,
            notchOnRight: true),
        size: const Size(200, 60),
      );
      // 凹口頂點在 x=170、y=30；再往右 5px 仍在凹口內 → 應是背景（黑）
      expect(near(at(178, 30), hpRed), isFalse,
          reason: '凹口中央不該有條色，實得 ${at(178, 30)}');
      // 但同一個 x 的上緣仍在條內 → 應是紅色
      expect(near(at(178, 3), hpRed), isTrue,
          reason: '凹口上方仍屬條身，實得 ${at(178, 3)}');
    });
  });

  group('MP 條（凹口在左）', () {
    testWidgets('由右往左填藍色，向菱形靠攏', (tester) async {
      final at = await render(
        tester,
        const NotchedBar(
            fraction: 0.5,
            color: mpBlue,
            height: 60,
            notch: 30,
            notchOnRight: false),
        size: const Size(200, 60),
      );
      // 右半填滿
      expect(near(at(190, 30), mpBlue), isTrue,
          reason: '右端應為藍色，實得 ${at(190, 30)}');
      // 左半未填（且 x=10,y=30 落在左側凹口內，更不該是藍）
      expect(near(at(60, 30), mpBlue), isFalse,
          reason: '左半不該是藍色，實得 ${at(60, 30)}');
    });

    testWidgets('左端凹口切在正確側', (tester) async {
      final at = await render(
        tester,
        const NotchedBar(
            fraction: 1.0,
            color: mpBlue,
            height: 60,
            notch: 30,
            notchOnRight: false),
        size: const Size(200, 60),
      );
      expect(near(at(22, 30), mpBlue), isFalse,
          reason: '左凹口中央不該有條色，實得 ${at(22, 30)}');
      expect(near(at(22, 3), mpBlue), isTrue,
          reason: '凹口上方仍屬條身，實得 ${at(22, 3)}');
    });
  });

  group('邊界值', () {
    testWidgets('fraction=0 時完全沒有填充色', (tester) async {
      final at = await render(
        tester,
        const NotchedBar(
            fraction: 0,
            color: hpRed,
            height: 60,
            notch: 30,
            notchOnRight: true),
        size: const Size(200, 60),
      );
      expect(near(at(10, 30), hpRed), isFalse);
    });

    testWidgets('fraction 超過 1 會被夾住，不會溢出條身', (tester) async {
      final at = await render(
        tester,
        const NotchedBar(
            fraction: 5,
            color: hpRed,
            height: 60,
            notch: 30,
            notchOnRight: true),
        size: const Size(200, 60),
      );
      // 凹口仍該是空的
      expect(near(at(178, 30), hpRed), isFalse);
    });
  });
}
