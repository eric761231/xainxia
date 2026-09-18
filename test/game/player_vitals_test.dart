import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_player_component.dart';

void main() {
  test('角色 HP/MP 可即時更新，缺少新上限時保留原值', () {
    final player = IsoPlayerComponent(
      initialTileX: 40,
      initialTileY: 40,
      mapData: IsoMapData.generic(minCoord: 31, maxCoord: 50),
      displayName: '測試角色',
      vitalHp: 80,
      vitalHpMax: 100,
      vitalMp: 30,
      vitalMpMax: 50,
    );

    player.applyVitals(hp: 42, hpMax: 0, mp: 18, mpMax: 60);

    expect(player.vitalHp, 42);
    expect(player.vitalHpMax, 100);
    expect(player.vitalMp, 18);
    expect(player.vitalMpMax, 60);
  });
}
