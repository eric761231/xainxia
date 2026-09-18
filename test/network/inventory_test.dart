import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/opcodes/client_opcodes.dart';
import 'package:xianxia_game/network/packets/client/c_item.dart';
import 'package:xianxia_game/network/packets/server/s_inventory.dart';

/// 背包封包的解析與語意。
///
/// 這裡釘住的重點是 **upsert**：S_ITEM_UPDATE 同時服務「撿到新道具」與
/// 「數量改變」，兩者共用一個封包。前端若把它當成「只會是更新」，
/// 撿到的新道具就不會出現在背包裡。
void main() {
  Map<String, dynamic> item({
    int objId = 900001,
    int itemId = 40010,
    int count = 3,
    String name = '治癒藥水',
    int itemType = 0,
    bool stackable = true,
    bool usable = true,
    bool equipped = false,
    int enchantLevel = 0,
  }) =>
      {
        'objId': objId,
        'itemId': itemId,
        'count': count,
        'name': name,
        'itemType': itemType,
        'stackable': stackable,
        'usable': usable,
        'equipped': equipped,
        'identified': true,
        'enchantLevel': enchantLevel,
      };

  group('S_INVENTORY', () {
    test('解析整份背包，模板欄位由伺服器帶來', () {
      // 前端不持有 item 表 —— 名稱與類型都在封包裡
      final inv = SInventory.fromData({
        'items': [
          item(),
          item(objId: 900002, itemId: 4, count: 1, name: '長劍',
              itemType: 1, stackable: false, usable: false),
        ],
        'size': 2,
      });
      expect(inv.items, hasLength(2));
      expect(inv.items.first.name, '治癒藥水');
      expect(inv.items.first.usable, isTrue);
      expect(inv.items[1].isWeapon, isTrue);
      expect(inv.items[1].stackable, isFalse);
    });

    test('空背包不拋例外', () {
      expect(SInventory.fromData({}).items, isEmpty);
      expect(SInventory.fromData({'items': []}).items, isEmpty);
    });
  });

  group('道具分類', () {
    test('itemType 對應武器與防具', () {
      expect(InventoryItem.fromJson(item(itemType: 1)).isWeapon, isTrue);
      expect(InventoryItem.fromJson(item(itemType: 2)).isArmor, isTrue);
      final etc = InventoryItem.fromJson(item(itemType: 0));
      expect(etc.isWeapon, isFalse);
      expect(etc.isArmor, isFalse);
    });

    test('強化等級顯示成 +N，0 不顯示', () {
      expect(InventoryItem.fromJson(item(name: '長劍')).displayName, '長劍');
      expect(
          InventoryItem.fromJson(item(name: '長劍', enchantLevel: 3)).displayName,
          '長劍 +3');
    });
  });

  group('S_ITEM_UPDATE 是 upsert', () {
    test('解析單一道具', () {
      final u = SItemUpdate.fromData({'item': item(count: 2)});
      expect(u.item.objId, 900001);
      expect(u.item.count, 2);
    });

    test('缺 item 欄位時退回空道具而非拋例外', () {
      final u = SItemUpdate.fromData({});
      expect(u.item.objId, 0);
      expect(u.item.name, '');
    });
  });

  group('S_ITEM_REMOVE', () {
    test('只帶 objId', () {
      expect(SItemRemove.fromData({'objId': 900001}).objId, 900001);
    });
  });

  group('送出的封包', () {
    test('使用與丟棄都以 objId 指定，不是 itemId', () {
      // 同種道具可能有多筆（不可疊加的武器），用 itemId 會指到錯的那筆
      expect(CUseItem.build(objId: 900001), {
        'op': ClientOpcodes.cUseItem,
        'data': {'objId': 900001},
      });
      expect(CDropItem.build(objId: 900002, count: 5), {
        'op': ClientOpcodes.cDropItem,
        'data': {'objId': 900002, 'count': 5},
      });
    });

    test('丟棄預設一個', () {
      expect(CDropItem.build(objId: 1)['data'], {'objId': 1, 'count': 1});
    });
  });
}
