import 'dart:convert';
import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/l1_sprite_sheet.dart';

/// `character_sprites.json` 的約束。
///
/// 這份設定被換掉過一次：female 指向 `female_base_aligned.png`，而那是**另一個
/// 角色**的走路表（藍白仙俠裝，120px），不是 3221（紫衣 L1，59px）的高解析版。
/// 換過去等於同時換了造型、而且只剩 walk —— 3221 的 attack 與 death 全部消失，
/// 兩端都不會報錯。這些測試把那次的教訓釘住。
late final ui.Image _stubImage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder);
    _stubImage = await recorder.endRecording().toImage(1, 1);
  });

  Map<String, dynamic> config() => jsonDecode(
        File('assets/data/character_sprites.json').readAsStringSync(),
      ) as Map<String, dynamic>;

  Map<String, dynamic> sheets() =>
      config()['sheets'] as Map<String, dynamic>;

  test('男女都使用 3221 的 L1 圖集，且圖檔存在', () {
    for (final entry in sheets().entries) {
      final sheet = entry.value as Map<String, dynamic>;
      expect(sheet['l1'], 'assets/characters/3221.png',
          reason: '${entry.key} 必須用 3221；female_base_aligned 是別的角色');
      expect(File(sheet['l1'] as String).existsSync(), isTrue);
    }
    expect(File('assets/characters/3221.json').existsSync(), isTrue);
  });

  test('3221.json 提供 walk / attack / death 的八向影格', () {
    final meta = jsonDecode(
      File('assets/characters/3221.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final animations = meta['animations'] as Map<String, dynamic>;

    // L1SpriteSheet 的動作區間：walk 0..7、attack 16..23、death 96..103。
    for (final range in const {'walk': 0, 'attack': 16, 'death': 96}.entries) {
      for (var facing = 0; facing < 8; facing++) {
        final key = '3221-${range.value + facing}';
        expect(animations.containsKey(key), isTrue,
            reason: '${range.key} 缺少 $key');
      }
    }
  });

  test('renderScale 在合理範圍內，且男女一致', () {
    final scales = <num>[];
    for (final entry in sheets().entries) {
      final scale = (entry.value as Map<String, dynamic>)['renderScale'] as num;
      expect(scale, inInclusiveRange(0.5, 4),
          reason: '${entry.key} 的 renderScale 超出合理範圍');
      scales.add(scale);
    }
    expect(scales.toSet().length, 1, reason: '男女角色不該一大一小');
  });

  test('非整數倍會改用平滑取樣（否則邊緣階梯不均勻）', () {
    // 規則在 IsoPlayerComponent：整數倍用 FilterQuality.none（一個來源像素對應
    // N×N，點陣圖最銳利），非整數倍改用 medium。這裡只釘住 L1SpriteComponent
    // 有這個開關、且預設維持原本的 none。
    final sheet = L1SpriteSheet(
      image: _stubImage,
      animations: const {},
      actions: const [],
      tileWidth: 56,
      facingMap: const [0, 1, 2, 3, 4, 5, 6, 7],
    );
    expect(
      L1SpriteComponent(sheet: sheet, action: 'walk', facing: 0).filterQuality,
      FilterQuality.none,
    );
    expect(
      L1SpriteComponent(
        sheet: sheet,
        action: 'walk',
        facing: 0,
        filterQuality: FilterQuality.medium,
      ).filterQuality,
      FilterQuality.medium,
    );
  });

  test('defaultKey 指向存在的 sheet', () {
    final c = config();
    expect(sheets().containsKey(c['defaultKey']), isTrue);
  });
}
