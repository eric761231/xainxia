import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/opcodes/client_opcodes.dart';
import 'package:xianxia_game/network/packets/client/c_attack.dart';
import 'package:xianxia_game/network/packets/server/s_monster_pack.dart';

/// 戰鬥相關的前端邏輯。
///
/// 重點在「點哪一格會打誰」的判定 —— 選錯目標的症狀是「打不到」或
/// 「打到不該打的東西」，而封包本身完全正常，很難從 log 看出問題。
void main() {
  /// 重現 MyGame.monsterObjIdAt 的規則。
  int monsterAt(List<MonsterObject> monsters, int x, int y) {
    for (final m in monsters) {
      if (m.x == x && m.y == y && m.currentHp > 0) return m.objId;
    }
    return 0;
  }

  List<MonsterObject> pack() => SMonsterPack.fromData({
        'mapId': 0,
        'monsters': [
          {
            'objId': 2000000000,
            'name': '山野狼',
            'x': 38,
            'y': 38,
            'heading': 2,
            'npcId': 45000,
            'gfxid': 1,
            'maxHp': 40,
            'currentHp': 40,
          },
          {
            'objId': 2000000001,
            'name': '洞穴蝠',
            'x': 36,
            'y': 44,
            'heading': 0,
            'npcId': 45001,
            'gfxid': 2,
            'maxHp': 25,
            'currentHp': 0, // 已死，屍體還在畫面上
          },
        ],
      }).monsters;

  group('點擊命中', () {
    test('點到怪物回傳它的 objId', () {
      expect(monsterAt(pack(), 38, 38), 2000000000);
    });

    test('空地回 0（走過去，不是揮刀）', () {
      expect(monsterAt(pack(), 40, 40), 0);
    });

    test('血量 0 的不算目標 —— 屍體還在畫面上但不該能再打', () {
      expect(monsterAt(pack(), 36, 44), 0);
    });
  });

  group('怪物血量同步', () {
    test('copyWith 只換血量，位置與名稱不動', () {
      // S_HP_UPDATE 只帶血量，其餘欄位要保留
      final m = pack().first.copyWith(currentHp: 12);
      expect(m.currentHp, 12);
      expect(m.x, 38);
      expect(m.name, '山野狼');
      expect(m.maxHp, 40);
    });
  });

  group('C_ATTACK', () {
    test('只帶目標 objId —— 距離與合法性由伺服器判定', () {
      expect(CAttack.build(targetObjId: 2000000000), {
        'op': ClientOpcodes.cAttack,
        'data': {'targetObjId': 2000000000},
      });
    });
  });
}
