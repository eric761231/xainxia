import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_player_component.dart';

/// 點擊移動的尋路。
///
/// 以前是朝目標直線走、下一格被擋就放棄 —— 點到家具或障礙後方時人完全不動。
/// 現在要能繞路，走不到就停在離目標最近的格子。
void main() {
  // 可走區 0..10；外圈一圈是不可走的邊界
  IsoMapData makeMap() => IsoMapData.generic(
        minCoord: 0,
        maxCoord: 10,
        mapId: 0,
        tileWidth: 48,
        tileHeight: 24,
      );

  void block(IsoMapData data, int x, int y) {
    data.collisionLayer!.data[data.toIndex(y)][data.toIndex(x)] = 1;
  }

  Future<IsoPlayerComponent> spawn(IsoMapData data, int x, int y) async {
    final player = IsoPlayerComponent(
      initialTileX: x,
      initialTileY: y,
      mapData: data,
    );
    await player.onLoad();
    return player;
  }

  /// 一直走到停下；回傳經過的每一格。
  List<(int, int)> walk(IsoPlayerComponent player) {
    final visited = <(int, int)>[];
    for (var i = 0; i < 200; i++) {
      player.update(IsoPlayerComponent.stepDuration);
      final cell = (player.tileX, player.tileY);
      if (visited.isEmpty || visited.last != cell) visited.add(cell);
      if (player.isIdle) break;
    }
    return visited;
  }

  test('點到被擋的格子：走過去停在旁邊，而不是原地不動', () async {
    final data = makeMap();
    block(data, 8, 5);
    final player = await spawn(data, 2, 5);

    player.moveTo(8, 5);
    walk(player);

    expect((player.tileX, player.tileY), (7, 5));
    expect(player.isIdle, isTrue);
  });

  test('中間有牆：繞過去而不是撞牆停下', () async {
    final data = makeMap();
    for (var y = 2; y <= 8; y++) {
      block(data, 5, y);
    }
    final player = await spawn(data, 3, 5);

    player.moveTo(7, 5);
    final path = walk(player);

    expect((player.tileX, player.tileY), (7, 5));
    for (final (x, y) in path) {
      expect(data.isBlocked(x, y), isFalse, reason: '路徑穿過了被擋的格子 ($x,$y)');
    }
  });

  test('斜走不切角：兩側都被擋時不能從縫隙穿過', () async {
    final data = makeMap();
    block(data, 6, 5);
    block(data, 5, 6);
    final player = await spawn(data, 5, 5);

    final path = player.findPath(5, 5, 6, 6);

    expect(path, isNotEmpty);
    expect(path.first, isNot((6, 6)), reason: '第一步直接斜穿了兩個障礙物之間的角');
    var (px, py) = (5, 5);
    for (final (x, y) in path) {
      final dx = x - px, dy = y - py;
      if (dx != 0 && dy != 0) {
        expect(data.isBlocked(px + dx, py) || data.isBlocked(px, py + dy), isFalse,
            reason: '($px,$py)→($x,$y) 切角');
      }
      (px, py) = (x, y);
    }
    expect(path.last, (6, 6));
  });

  test('被圍住走不出去：不移動，只轉向目標', () async {
    final data = makeMap();
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx != 0 || dy != 0) block(data, 5 + dx, 5 + dy);
      }
    }
    final player = await spawn(data, 5, 5);

    player.moveTo(9, 5);
    walk(player);

    expect((player.tileX, player.tileY), (5, 5));
    expect(player.facing, IsoPlayerComponent.facingFromDelta(1, 0));
  });

  test('出發後路被擋住：重新尋路繞過去', () async {
    final data = makeMap();
    final player = await spawn(data, 2, 5);

    player.moveTo(8, 5);
    player.update(IsoPlayerComponent.stepDuration); // 走出第一步
    block(data, 5, 5);
    walk(player);

    expect((player.tileX, player.tileY), (8, 5));
  });
}
