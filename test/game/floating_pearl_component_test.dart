import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/floating_weapon_component.dart';

void main() {
  test('靈珠流紋採六格、每格 128px、0.14 秒循環', () {
    expect(FloatingPearlComponent.frameCount, 6);
    expect(FloatingPearlComponent.frameSize, 128);
    expect(FloatingPearlComponent.flowStepTime, .14);
  });

  test('靈珠有完整八向定位，且依 facing 順序可重複取得', () {
    final expected = <List<double>>[
      [22, -50],
      [28, -42],
      [24, -34],
      [18, -32],
      [-18, -32],
      [-26, -42],
      [-22, -50],
      [-16, -56],
    ];

    for (var facing = 0; facing < 8; facing++) {
      final offset = FloatingPearlComponent.homeOffsetFor(facing);
      expect(offset.x, expected[facing][0]);
      expect(offset.y, expected[facing][1]);
    }
  });

  test('超出範圍的 facing 安全夾住，避免未知封包讓武器消失', () {
    expect(FloatingPearlComponent.homeOffsetFor(-3).x, 22);
    expect(FloatingPearlComponent.homeOffsetFor(99).x, -16);
  });
}
