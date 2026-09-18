import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/packets/server/s_pc_pack.dart';

/// S_PC_PACK 的語意：**整份名單**，不是增量。
///
/// 名單含收件者自己，由前端濾掉 —— 伺服器對每張地圖只算一次名單，
/// 不會為每個人各做一份少了自己的版本。這條規則寫錯的症狀是
/// 「畫面上多出一個自己」或「別人永遠留在畫面上」。
void main() {
  group('SPcPack', () {
    test('解析名單', () {
      final pack = SPcPack.fromData(const {
        'mapId': 1,
        'players': [
          {
            'objId': 10099,
            'name': '洛清塵',
            'x': 40,
            'y': 41,
            'heading': 3,
            'sex': 1,
            'level': 5,
          },
        ],
      });
      expect(pack.mapId, 1);
      expect(pack.players, hasLength(1));
      final p = pack.players.single;
      expect(p.objId, 10099);
      expect(p.name, '洛清塵');
      expect(p.x, 40);
      expect(p.y, 41);
      expect(p.heading, 3);
      expect(p.sex, 1);
      expect(p.level, 5);
    });

    test('空名單代表圖上只剩自己', () {
      final pack = SPcPack.fromData(const {'mapId': 0, 'players': []});
      expect(pack.players, isEmpty);
    });

    test('缺欄位時用安全預設值，不會拋例外', () {
      final pack = SPcPack.fromData(const {
        'players': [<String, dynamic>{}],
      });
      final p = pack.players.single;
      expect(p.name, '');
      expect(p.heading, 2); // 預設面向 SE，與角色出生面向一致
      expect(p.sex, 0);
      expect(p.level, 1);
    });
  });
}
