import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_player_component.dart';

void main() {
  test('48x24 等距格網的八方向依畫面順時針排列', () {
    const cases = <(int, int, int)>[
      (0, -1, 0), // NE
      (1, -1, 1), // E
      (1, 0, 2), // SE
      (1, 1, 3), // S
      (0, 1, 4), // SW
      (-1, 1, 5), // W
      (-1, 0, 6), // NW
      (-1, -1, 7), // N
    ];

    for (final (dx, dy, facing) in cases) {
      expect(
        IsoPlayerComponent.facingFromDelta(dx, dy),
        facing,
        reason: 'tile delta ($dx, $dy)',
      );
    }
  });

  test('一輪 walk 的 0.32 秒剛好移動一格並落在格子中心', () async {
    final data = IsoMapData.generic(
      minCoord: 0,
      maxCoord: 10,
      mapId: 0,
      tileWidth: 48,
      tileHeight: 24,
    );
    final player = IsoPlayerComponent(
      initialTileX: 5,
      initialTileY: 5,
      mapData: data,
    );
    await player.onLoad();
    final start = player.position.clone();

    player.moveTo(6, 5);
    player.update(0); // 啟動第一步
    player.update(IsoPlayerComponent.stepDuration / 2);
    expect(player.position.x, closeTo(start.x + 12, 0.001));
    expect(player.position.y, closeTo(start.y + 6, 0.001));
    expect(player.isMoving, isTrue);

    player.update(IsoPlayerComponent.stepDuration / 2);
    expect(player.position.x, closeTo(start.x + 24, 0.001));
    expect(player.position.y, closeTo(start.y + 12, 0.001));
    expect(player.isMoving, isFalse);
    expect(player.tileX, 6);
    expect(player.tileY, 5);
  });

  test('連續走兩格才播完一輪 walk；停下一陣子再走從第一步開始', () async {
    final data = IsoMapData.generic(
      minCoord: 0,
      maxCoord: 10,
      mapId: 0,
      tileWidth: 48,
      tileHeight: 24,
    );
    final player = IsoPlayerComponent(
      initialTileX: 2,
      initialTileY: 5,
      mapData: data,
    );
    await player.onLoad();

    player.moveTo(6, 5);
    player.update(0); // 踏出第一格
    player.update(IsoPlayerComponent.stepDuration / 2);
    expect(player.walkCycleProgress, closeTo(0.25, 1e-6));

    player.update(IsoPlayerComponent.stepDuration / 2); // 第一格走完，同一幀踏出第二格
    player.update(IsoPlayerComponent.stepDuration / 2);
    expect(player.walkCycleProgress, closeTo(0.75, 1e-6));

    // 走到終點後停一秒，再出發要從頭開始
    for (var i = 0; i < 20; i++) {
      player.update(IsoPlayerComponent.stepDuration / 2);
    }
    expect(player.isIdle, isTrue);
    player.update(1.0);
    player.moveTo(5, 5);
    player.update(0);
    player.update(IsoPlayerComponent.stepDuration / 2);
    expect(player.walkCycleProgress, closeTo(0.25, 1e-6));
  });
}
