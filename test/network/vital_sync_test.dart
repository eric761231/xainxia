import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/models/game_character.dart';
import 'package:xianxia_game/network/packets/server/s_hp_update.dart';
import 'package:xianxia_game/network/packets/server/s_mp_update.dart';

/// 血魔同步到 HUD 的規則。
///
/// 兩個容易錯的地方：
///   1. **要回寫 liveStatsNotifier**，否則血條只有進圖那一瞬間準確
///   2. **要比對 objId**，因為 S_HP_UPDATE 是廣播的 —— 隊友的血量也會送來，
///      不過濾就會拿隊友的數字更新自己的 HUD
void main() {
  GameCharacter base() => GameCharacter.fromMap({
        'name': '月蒼海',
        'level': 12,
        'hp': 10,
        'hpMax': 200,
        'mp': 30,
        'mpMax': 100,
        'exp': 500,
        'expMax': 1000,
      });

  /// 重現 GameWorldService._onHpUpdate 的判斷。
  GameCharacter? applyHp(GameCharacter c, SHpUpdate u, int selfObjId) {
    if (u.objId != selfObjId) return c;
    return c.copyWith(hp: u.currentHp, hpMax: u.maxHp);
  }

  GameCharacter? applyMp(GameCharacter c, SMpUpdate u, int selfObjId) {
    if (u.objId != selfObjId) return c;
    return c.copyWith(mp: u.currentMp, mpMax: u.maxMp);
  }

  group('血量', () {
    test('自己的更新會反映到血條', () {
      final c = applyHp(base(),
          SHpUpdate.fromData({'objId': 10002, 'currentHp': 60, 'maxHp': 200}),
          10002)!;
      expect(c.hp, 60);
      expect(c.hpFraction, closeTo(0.3, 1e-9));
    });

    test('隊友的更新不動自己的血條', () {
      // 沒有這道過濾，隊友掉血自己的 HUD 也會跟著掉
      final c = applyHp(base(),
          SHpUpdate.fromData({'objId': 99999, 'currentHp': 5, 'maxHp': 500}),
          10002)!;
      expect(c.hp, 10, reason: '應維持自己的血量');
      expect(c.hpMax, 200);
    });

    test('上限改變時分母跟著換（例如突破後）', () {
      final c = applyHp(base(),
          SHpUpdate.fromData({'objId': 10002, 'currentHp': 300, 'maxHp': 600}),
          10002)!;
      expect(c.hpFraction, closeTo(0.5, 1e-9));
    });
  });

  group('魔力', () {
    test('自己的更新會反映到魔條', () {
      final c = applyMp(base(),
          SMpUpdate.fromData({'objId': 10002, 'currentMp': 80, 'maxMp': 100}),
          10002)!;
      expect(c.mpFraction, closeTo(0.8, 1e-9));
    });

    test('隊友的不影響', () {
      final c = applyMp(base(),
          SMpUpdate.fromData({'objId': 1, 'currentMp': 0, 'maxMp': 100}),
          10002)!;
      expect(c.mp, 30);
    });
  });

  group('HUD 取值的容錯', () {
    test('上限為 0 時比例回 0，不是 NaN', () {
      // 直接算 hp/hpMax 會產生 NaN，畫進度條時整條會消失
      final c = GameCharacter.fromMap(
          {'name': 'x', 'hp': 0, 'hpMax': 0, 'mp': 0, 'mpMax': 0});
      expect(c.hpFraction, 0);
      expect(c.mpFraction, 0);
      expect(c.expFraction, 0);
    });

    test('比例夾在 0..1（伺服器送超量也不會溢出）', () {
      final c = GameCharacter.fromMap(
          {'name': 'x', 'hp': 999, 'hpMax': 100, 'mp': 0, 'mpMax': 100});
      expect(c.hpFraction, 1.0);
    });
  });
}
