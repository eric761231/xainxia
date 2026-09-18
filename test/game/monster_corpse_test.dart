import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_monster_component.dart';
import 'package:xianxia_game/game/map/iso_player_component.dart';

/// 怪物死亡的屍體表演：倒地 → 淡成半透明 → 停留幾秒 → 移除。
///
/// 伺服器在死亡當下就送 S_OBJECT_REMOVE，屍體完全是前端的時間軸，
/// 時間算錯只會「一死就不見」或「屍體永遠不消失」，不會有任何錯誤訊息。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final data = IsoMapData.generic(minCoord: 31, maxCoord: 50, mapId: 0);

  IsoMonsterComponent make({int hp = 10}) => createMonster(
        objId: 1,
        name: '測試怪',
        x: 40,
        y: 40,
        facing: 2,
        maxHp: 20,
        currentHp: hp,
        mapData: data,
      );

  test('淡成半透明後停留 corpseSeconds 秒才通知移除', () {
    final m = make(hp: 0);
    var gone = 0;
    m.beginCorpse(() => gone++);
    expect(m.isCorpse, isTrue);

    m.update(0.1);
    expect(m.opacity, lessThan(1.0));
    expect(m.opacity, greaterThan(IsoMonsterComponent.corpseOpacity));
    m.update(0.2); // 淡出完成
    expect(m.opacity, closeTo(IsoMonsterComponent.corpseOpacity, 1e-9));

    m.update(IsoMonsterComponent.corpseSeconds - 0.1);
    expect(gone, 0, reason: '屍體還沒停留滿就消失了');
    m.update(0.2);
    expect(gone, 1);

    m.update(1.0);
    expect(gone, 1, reason: '移除通知只能發一次');
  });

  test('重複 beginCorpse 不會重置計時', () {
    final m = make(hp: 0);
    var gone = 0;
    m.beginCorpse(() => gone++);
    m.update(0.3);
    m.update(IsoMonsterComponent.corpseSeconds - 0.5);
    m.beginCorpse(() => gone += 100);
    m.update(0.6);
    expect(gone, 1);
  });

  test('血量歸零後受傷與攻擊演出不再播放（不會打斷倒地）', () {
    final m = make(hp: 5);
    m.applyHp(0, 20);
    expect(() => m.playHurt(), returnsNormally);
    expect(() => m.playAttack(), returnsNormally);
    expect(m.currentHp, 0);
  });

  test('攻擊前轉向目標', () {
    final m = make();
    m.faceToward(41, 40);
    expect(m.facing, IsoPlayerComponent.facingFromDelta(1, 0));
    m.faceToward(40, 39);
    expect(m.facing, IsoPlayerComponent.facingFromDelta(0, -1));
  });
}
