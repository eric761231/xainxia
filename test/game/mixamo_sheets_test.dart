import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/l1_sprite_sheet.dart';

/// `tools/sprites/mixamo_to_l1.py` 產生的圖集。
///
/// 圖集要等 FBX 下載、跑過腳本才會存在；還沒產生的就跳過，不算失敗。
/// 解析錯了不會拋例外，只會讓角色浮空或少一個方向，所以逐項檢查。
void main() {
  const paths = [
    'assets/characters/brady.json',
    'assets/characters/kachujin.json',
    'assets/monsters/warrok.json',
    'assets/monsters/goblin.json',
    'assets/monsters/demon.json',
    'assets/monsters/skeletonzombie.json',
  ];

  for (final path in paths) {
    final file = File(path);
    test(
      '$path：5 個動作 × 8 方向齊全、rect 在圖內、站姿長在原點上方',
      () {
        final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final sheet = L1SpriteSheet.parse(_FakeImage(), j);
        expect(sheet, isNotNull);
        final size = (j['textureSize'] as List).cast<num>();

        for (final action in ['walk', 'idle', 'attack', 'hurt', 'death']) {
          expect(sheet!.has(action), isTrue, reason: '$path 缺少動作 $action');
          for (var f = 0; f < 8; f++) {
            final anim = sheet.get(action, f);
            expect(anim, isNotNull, reason: '$path 缺少 $action-$f');
            expect(anim!.frames, isNotEmpty);
            for (final frame in anim.frames) {
              expect(frame.src.left, greaterThanOrEqualTo(0));
              expect(frame.src.top, greaterThanOrEqualTo(0));
              expect(frame.src.right, lessThanOrEqualTo(size[0]));
              expect(frame.src.bottom, lessThanOrEqualTo(size[1]));
              // 倒地的死亡幀可能畫到原點下方，只檢查站著的動作
              if (action == 'walk' || action == 'idle') {
                expect(
                  frame.offset.y,
                  lessThan(0),
                  reason: '$path $action-$f 整個畫在原點下方',
                );
              }
            }
          }
        }
      },
      skip: file.existsSync()
          ? false
          : '尚未產生，先執行 python tools/sprites/mixamo_to_l1.py',
    );
  }
}

/// 解析不需要真的圖，只要一個非 null 的 ui.Image 佔位。
class _FakeImage implements ui.Image {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}
