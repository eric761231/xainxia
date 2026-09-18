import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/opcodes/client_opcodes.dart';
import 'package:xianxia_game/network/packets/client/c_place_property.dart';
import 'package:xianxia_game/network/packets/server/s_map_collision.dart';
import 'package:xianxia_game/network/packets/server/s_map_info.dart';
import 'package:xianxia_game/network/packets/server/s_property_pack.dart';

/// 家具佔用該格嗎？與伺服器 DecorationInstance.occupies() 同式。
///
/// 這裡重寫一份而非匯入 MyGame 的私有函式，是因為 MyGame 需要完整的 Flame
/// 環境才能實例化。公式短且穩定，重複的代價低於把它挖出來的耦合。
bool occupies(PropertyObject p, int x, int y) {
  final w = p.footprintW < 1 ? 1 : p.footprintW;
  final h = p.footprintH < 1 ? 1 : p.footprintH;
  return x <= p.x && x > p.x - w && y <= p.y && y > p.y - h;
}

PropertyObject table({int x = 41, int y = 45, int w = 2, int h = 3}) =>
    SPropertyPack.fromData({
      'mapId': 0,
      'properties': [
        {
          'objId': 2000000002,
          'name': '木桌一',
          'x': x,
          'y': y,
          'propertyId': 1200,
          'pngid': 1200,
          'blocking': true,
          'footprintW': w,
          'footprintH': h,
        }
      ]
    }).properties.single;

void main() {
  group('footprint 命中判定', () {
    // 修正前 objIdAt 只比對錨點格，玩家點桌面中央會查不到東西，
    // 拆除與搬動都像是沒有反應。這組測試釘住「整個佔格都算命中」。
    test('2x3 的桌子，六格全部命中', () {
      final t = table();
      for (var dy = 0; dy < 3; dy++) {
        for (var dx = 0; dx < 2; dx++) {
          expect(occupies(t, 41 - dx, 45 - dy), isTrue,
              reason: '(${41 - dx},${45 - dy}) 應在佔格內');
        }
      }
    });

    test('錨點格以外的邊界格不命中', () {
      final t = table();
      expect(occupies(t, 42, 45), isFalse, reason: 'x 超出錨點');
      expect(occupies(t, 39, 45), isFalse, reason: 'x 超出寬度');
      expect(occupies(t, 41, 46), isFalse, reason: 'y 超出錨點');
      expect(occupies(t, 41, 42), isFalse, reason: 'y 超出深度');
    });

    test('鏡像的 3x2 展開方向相同（都往 x、y 遞減）', () {
      final t = table(w: 3, h: 2);
      expect(occupies(t, 39, 44), isTrue);
      expect(occupies(t, 38, 45), isFalse);
      expect(occupies(t, 41, 43), isFalse);
    });

    test('footprint 為 0 時當成 1x1，不會整張圖都命中', () {
      final t = table(w: 0, h: 0);
      expect(occupies(t, 41, 45), isTrue);
      expect(occupies(t, 40, 45), isFalse);
    });
  });

  group('C_MOVE_PROPERTY', () {
    test('帶 objId 與目標格座標', () {
      final p = CMoveProperty.build(objId: 2000000002, x: 40, y: 44);
      expect(p['op'], ClientOpcodes.cMoveProperty);
      expect(p['data'], {'objId': 2000000002, 'x': 40, 'y': 44});
    });
  });

  group('C_GM_COLLISION', () {
    test('標記與取消各自帶 blocked 旗標', () {
      expect(CGmCollision.build(x: 40, y: 41, blocked: true)['data'],
          {'x': 40, 'y': 41, 'blocked': true});
      expect(CGmCollision.build(x: 40, y: 41, blocked: false)['data'],
          {'x': 40, 'y': 41, 'blocked': false});
    });
  });

  group('地形碰撞解析', () {
    test('S_MAP_COLLISION 解析座標對', () {
      final c = SMapCollision.fromData({
        'mapId': 0,
        'blocked': [
          [40, 41],
          [40, 42]
        ]
      });
      expect(c.mapId, 0);
      expect(c.blocked, [(40, 41), (40, 42)]);
    });

    test('格式不符的元素略過而非拋例外', () {
      // 一格壞掉不該讓整張地圖的碰撞都收不到
      final c = SMapCollision.fromData({
        'blocked': [
          [40, 41],
          [40],
          'x',
          [43, 44]
        ]
      });
      expect(c.blocked, [(40, 41), (43, 44)]);
    });

    test('缺欄位或空清單都回空', () {
      expect(SMapCollision.fromData({}).blocked, isEmpty);
      expect(SMapCollision.fromData({'blocked': []}).blocked, isEmpty);
    });

    test('S_MAP_INFO 搭載的 blocked 與 S_MAP_COLLISION 同格式', () {
      final info = SMapInfo.fromData({
        'mapId': 0,
        'mapName': '修練洞府',
        'width': 20,
        'height': 20,
        'portals': [],
        'blocked': [
          [31, 31]
        ],
      });
      expect(info.blocked, [(31, 31)]);
    });

    test('舊版伺服器沒送 blocked 時不影響其餘欄位', () {
      final info = SMapInfo.fromData({
        'mapId': 1,
        'mapName': '梅花村',
        'portals': [],
      });
      expect(info.blocked, isEmpty);
      expect(info.mapName, '梅花村');
    });
  });
}
