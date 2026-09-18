import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_coord.dart';
import 'package:xianxia_game/game/map/stone_floor.dart';

/// 把石板地面畫成 PNG，方便用眼睛檢查磨損效果。
///
/// 不是斷言式測試 —— 地面好不好看沒辦法用 expect 判斷。它的用途是產出圖片
/// 讓人（或我）直接看，取代「改完進遊戲、截圖、再回來調」的長迴圈。
/// 順帶驗證 painter 不會拋例外，且同一格重畫兩次結果一致（決定性）。
class _FloorPainter extends CustomPainter {
  _FloorPainter(this.grid, this.halfW, this.halfH);
  final int grid;
  final double halfW;
  final double halfH;

  @override
  void paint(Canvas canvas, Size size) {
    // 底色：模擬遊戲裡的底圖（石板層是半透明的，需要有東西透出來）
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF6B563F));

    canvas.translate(size.width / 2, 20);
    for (var ty = 0; ty < grid; ty++) {
      for (var tx = 0; tx < grid; tx++) {
        final sp = IsoCoord.tileToScreen(tx, ty, halfW, halfH);
        final path = Path()
          ..moveTo(sp.x, sp.y)
          ..lineTo(sp.x + halfW, sp.y + halfH)
          ..lineTo(sp.x, sp.y + halfH * 2)
          ..lineTo(sp.x - halfW, sp.y + halfH)
          ..close();
        StoneFloor.paintTile(canvas, path, tx, ty, sp.x, sp.y, halfW, halfH);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  testWidgets('輸出石板地面預覽圖', (tester) async {
    const grid = 12;
    const halfW = 32.0;
    const halfH = 16.0;
    const size = Size(880, 460);

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: CustomPaint(painter: _FloorPainter(grid, halfW, halfH)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    // toImage 是引擎的真實非同步工作，假時鐘不會推進 —— 必須包 runAsync，
    // 否則測試會卡到逾時（先前踩過這個坑）。
    late ui.Image image;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: 2.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('stone_floor_preview.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });

    expect(tester.takeException(), isNull);
    expect(image.width, greaterThan(0));
  });

  testWidgets('決定性：畫兩次的像素完全相同（不會逐幀閃爍）', (tester) async {
    // 若改用 Random()，每幀都會抽到不同的裂痕與深淺，整片地面會閃爍。
    // 這條測試直接對拍兩次繪製的位元組，是唯一能證明「不閃」的方式。
    Future<List<int>> renderOnce() async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 240,
              height: 160,
              child: CustomPaint(painter: _FloorPainter(5, 32, 16)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late List<int> bytes;
      await tester.runAsync(() async {
        final img = await boundary.toImage();
        final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        bytes = d!.buffer.asUint8List().toList();
        img.dispose();
      });
      return bytes;
    }

    final first = await renderOnce();
    final second = await renderOnce();
    expect(second, equals(first));
  });
}
