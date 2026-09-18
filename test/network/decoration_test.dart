import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/opcodes/client_opcodes.dart';
import 'package:xianxia_game/network/packets/client/c_place_property.dart';
import 'package:xianxia_game/network/packets/server/s_placeable_list.dart';
import 'package:xianxia_game/network/packets/server/s_property_pack.dart';

/// 洞府布置的封包欄位。
///
/// 家具與世界物件共用 S_PROPERTY_PACK 的格式，前端因此只有一條解析路徑；
/// 這裡釘住兩者的欄位一致，尤其是玩家家具才會用到的 offsetX/offsetY。
void main() {
  group('C_PLACE_PROPERTY', () {
    test('帶物件編號與格座標', () {
      final p = CPlaceProperty.build(propertyId: 1200, x: 40, y: 41);
      expect(p['op'], ClientOpcodes.cPlaceProperty);
      expect(p['data'], {'propertyId': 1200, 'x': 40, 'y': 41});
    });

    test('C_REMOVE_PROPERTY 以 objId 指定', () {
      final p = CRemoveProperty.build(objId: 2000000002);
      expect(p['op'], ClientOpcodes.cRemoveProperty);
      expect(p['data'], {'objId': 2000000002});
    });

    test('C_PLACEABLE_LIST 無參數', () {
      final p = CPlaceableList.build();
      expect(p['op'], ClientOpcodes.cPlaceableList);
      expect(p['data'], isEmpty);
    });
  });

  group('S_PLACEABLE_LIST', () {
    test('解析可放置清單與放置面規則', () {
      final l = SPlaceableList.fromData({
        'items': [
          {
            'propertyId': 1200,
            'pngid': 1200,
            'name': '木桌一',
            'placement': 'floor',
            'blocking': true,
            'footprintW': 1,
            'footprintH': 1,
          },
          {
            'propertyId': 1300,
            'pngid': 1300,
            'name': '窗',
            'placement': 'wall',
            'blocking': false,
            'footprintW': 1,
            'footprintH': 1,
          },
        ]
      });
      expect(l.items, hasLength(2));
      expect(l.items.first.name, '木桌一');
      expect(l.items.first.isFloor, isTrue);
      expect(l.items.first.isWall, isFalse);
      expect(l.items.first.blocking, isTrue);
      // 壁掛物：放在不可走格，且不擋路
      expect(l.items[1].isWall, isTrue);
      expect(l.items[1].blocking, isFalse);
    });

    test('未知 placement 預設當成地面', () {
      final l = SPlaceableList.fromData({
        'items': [
          {'propertyId': 1, 'pngid': 1, 'name': 'x'}
        ]
      });
      expect(l.items.single.placement, 'floor');
      expect(l.items.single.isFloor, isTrue);
    });

    test('空清單不拋例外', () {
      expect(SPlaceableList.fromData({}).items, isEmpty);
    });
  });

  group('S_PROPERTY_PACK 的家具欄位', () {
    test('帶像素微調（壁掛物往上推到牆面高度）', () {
      final pack = SPropertyPack.fromData({
        'mapId': 0,
        'properties': [
          {
            'objId': 2000000002,
            'name': '木桌一',
            'x': 41,
            'y': 45,
            'heading': 2,
            'propertyId': 1200,
            'pngid': 1200,
            'blocking': true,
            'footprintW': 1,
            'footprintH': 1,
            'offsetX': 0,
            'offsetY': -48,
            'action': false,
            'actionType': 0,
            'value': 0,
          }
        ]
      });
      final o = pack.properties.single;
      expect(o.objId, 2000000002);
      expect(o.propertyId, 1200);
      expect(o.offsetX, 0);
      expect(o.offsetY, -48);
      expect(o.blocking, isTrue);
    });

    test('世界物件沒有 offset 欄位時預設 0', () {
      final pack = SPropertyPack.fromData({
        'mapId': 1,
        'properties': [
          {'objId': 1, 'x': 31, 'y': 31, 'propertyId': 1010, 'pngid': 1010}
        ]
      });
      expect(pack.properties.single.offsetX, 0);
      expect(pack.properties.single.offsetY, 0);
    });
  });
}
