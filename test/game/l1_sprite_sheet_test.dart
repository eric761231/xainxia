import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/l1_sprite_sheet.dart';

/// L1 圖集的解析。
///
/// 這個格式的重點是**逐幀 offset** —— 它決定每一幀畫在哪。解析錯了不會拋例外，
/// 只會讓角色浮空或陷進地板，而且在單張圖上看不出來。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> meta(List<Map<String, dynamic>> frames) => {
    'tile': [48, 24],
    'actions': ['walk', 'death'],
    'animations': {
      'walk-0': {'frameCount': frames.length, 'frames': frames},
      'death-0': {'frameCount': 1, 'frames': frames.take(1).toList()},
    },
  };

  group('解析', () {
    test('rect 與 offset 逐幀保留', () {
      final s = L1SpriteSheet.parse(
        _FakeImage(),
        meta([
          {
            'frame': 0,
            'rect': [10, 20, 30, 40],
            'offset': [-15, -38],
          },
          {
            'frame': 1,
            'rect': [41, 20, 31, 40],
            'offset': [-16, -37],
          },
        ]),
      )!;
      final a = s.get('walk', 0)!;
      expect(a.frames, hasLength(2));
      expect(a.frames[0].src.left, 10);
      expect(a.frames[0].src.width, 30);
      // offset 為負＝畫在原點的左上方。角色站著時腳在原點，身體往上長。
      expect(a.frames[0].offset.x, -15);
      expect(a.frames[0].offset.y, -38);
      expect(a.frames[1].offset.x, -16);
    });

    test('動作查詢與 facing 夾取', () {
      final s = L1SpriteSheet.parse(
        _FakeImage(),
        meta([
          {
            'frame': 0,
            'rect': [0, 0, 8, 8],
            'offset': [0, 0],
          },
        ]),
      )!;
      expect(s.has('walk'), isTrue);
      expect(s.has('attack'), isFalse);
      expect(s.get('walk', 0), isNotNull);
      // 沒有的方向回 null，而不是拿錯一個方向來畫
      expect(s.get('walk', 5), isNull);
    });

    test('facing_map 將遊戲方向映射到素材方向', () {
      final j = meta([
        {
          'frame': 0,
          'rect': [0, 0, 8, 8],
          'offset': [0, 0],
        },
      ]);
      final anims = j['animations'] as Map<String, dynamic>;
      anims['walk-2'] = {
        'frameCount': 1,
        'frames': [
          {
            'frame': 0,
            'rect': [22, 0, 8, 8],
            'offset': [0, 0],
          },
        ],
      };
      j['facing_map'] = [2, 3, 4, 5, 6, 7, 0, 1];

      final s = L1SpriteSheet.parse(_FakeImage(), j)!;
      expect(s.get('walk', 0)!.frames.first.src.left, 22);
      expect(s.facingMap, [2, 3, 4, 5, 6, 7, 0, 1]);
    });

    test('frame_bottom_center 以每幀底部中心固定人物原點', () {
      final j = meta([
        {
          'frame': 0,
          'rect': [10, 20, 30, 40],
          'offset': [99, 88],
        },
        {
          'frame': 1,
          'rect': [41, 20, 20, 36],
          'offset': [-77, 66],
        },
      ]);
      j['anchor_mode'] = 'frame_bottom_center';

      final frames = L1SpriteSheet.parse(
        _FakeImage(),
        j,
      )!.get('walk', 0)!.frames;
      expect(frames[0].offset.x, -15);
      expect(frames[0].offset.y, -40);
      expect(frames[1].offset.x, -10);
      expect(frames[1].offset.y, -36);
    });

    test('一格移動進度平均驅動全部 walk 影格', () {
      final frames = List.generate(
        8,
        (i) => {
          'frame': i,
          'rect': [i * 8, 0, 8, 8],
          'offset': [-4, -8],
        },
      );
      final sheet = L1SpriteSheet.parse(_FakeImage(), meta(frames))!;
      final sprite = L1SpriteComponent(sheet: sheet, action: 'walk', facing: 0);

      sprite.setCycleProgress(0);
      expect(sprite.currentFrameIndex, 0);
      sprite.setCycleProgress(0.5);
      expect(sprite.currentFrameIndex, 4);
      sprite.setCycleProgress(1);
      expect(sprite.currentFrameIndex, 7);
    });

    test('tile 記錄產生時的格寬 —— 與現況不符就代表素材該重產', () {
      final s = L1SpriteSheet.parse(
        _FakeImage(),
        meta([
          {
            'frame': 0,
            'rect': [0, 0, 8, 8],
            'offset': [0, 0],
          },
        ]),
      )!;
      expect(s.tileWidth, 48);
    });

    test('缺 animations 時回 null，不拋例外', () {
      expect(
        L1SpriteSheet.parse(_FakeImage(), const {
          'tile': [48, 24],
        }),
        isNull,
      );
    });
  });

  group('實際素材', () {
    Future<Map<String, dynamic>> read(String p) async =>
        jsonDecode(await rootBundle.loadString(p)) as Map<String, dynamic>;

    test('狼的圖集：8 個方向齊全，且格寬與目前一致', () async {
      final path = 'assets/monsters/black_forest/mountain_wolf.json';
      final j = await read(path);
      expect((j['tile'] as List)[0], 48, reason: '$path 的格寬與目前不符');
      final anims = j['animations'] as Map<String, dynamic>;
      for (final action in (j['actions'] as List).cast<String>()) {
        for (var f = 0; f < 8; f++) {
          expect(
            anims.containsKey('$action-$f'),
            isTrue,
            reason: '$path 缺 $action-$f',
          );
        }
      }
    });

    test('3221 人物圖集解析：行走、站立休息、攻擊、受傷、死亡 5 種動作 8 方向齊全', () async {
      final path = 'assets/characters/3221.json';
      final j = await read(path);
      final sheet = L1SpriteSheet.parse(_FakeImage(), j);
      expect(sheet, isNotNull);
      expect(sheet!.facingMap, [2, 3, 4, 5, 6, 7, 0, 1]);
      for (final action in ['walk', 'idle', 'attack', 'hurt', 'death']) {
        expect(sheet.has(action), isTrue, reason: '3221 缺少動作 $action');
        for (var f = 0; f < 8; f++) {
          final anim = sheet.get(action, f);
          expect(anim, isNotNull, reason: '3221 缺少 $action-$f');
          expect(anim!.frames, isNotEmpty);
        }
      }
    });

    test('3221 走路每一幀的 offset y 為負 —— 身體要長在原點上方', () async {
      final path = 'assets/characters/3221.json';
      final j = await read(path);
      final sheet = L1SpriteSheet.parse(_FakeImage(), j)!;
      for (var f = 0; f < 8; f++) {
        final anim = sheet.get('walk', f)!;
        for (final fr in anim.frames) {
          expect(fr.offset.y, lessThan(0), reason: '走路的幀不該整個畫在原點下方');
        }
      }
    });

    test('3221 走路影格固定在原點，不再帶一格的素材位移', () async {
      final j = await read('assets/characters/3221.json');
      final sheet = L1SpriteSheet.parse(_FakeImage(), j)!;
      for (var f = 0; f < 8; f++) {
        final anim = sheet.get('walk', f)!;
        for (final frame in anim.frames) {
          expect(frame.offset.x + frame.src.width / 2, closeTo(0, 0.001));
          expect(frame.offset.y + frame.src.height, closeTo(0, 0.001));
        }
      }
    });
  });
}

/// 解析不需要真的圖，只要一個非 null 的 ui.Image 佔位。
class _FakeImage implements ui.Image {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}
