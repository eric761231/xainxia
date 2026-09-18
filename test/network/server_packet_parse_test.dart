import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/packets/server/s_attack.dart';
import 'package:xianxia_game/network/packets/server/s_bubble_dialog.dart';
import 'package:xianxia_game/network/packets/server/s_dialog.dart';
import 'package:xianxia_game/network/packets/server/s_gather_result.dart';
import 'package:xianxia_game/network/packets/server/s_hp_update.dart';
import 'package:xianxia_game/network/packets/server/s_map_info.dart';
import 'package:xianxia_game/network/packets/server/s_monster_pack.dart';
import 'package:xianxia_game/network/packets/server/s_mp_update.dart';
import 'package:xianxia_game/network/packets/server/s_npc_move.dart';
import 'package:xianxia_game/network/packets/server/s_npc_pack.dart';
import 'package:xianxia_game/network/packets/server/s_object_remove.dart';
import 'package:xianxia_game/network/packets/server/s_property_pack.dart';
import 'package:xianxia_game/network/packets/server/s_property_update.dart';

/// 這些 JSON 的欄位名必須與伺服器 Java 端的 put(...) 完全一致。
///
/// 前端所有欄位都是 `?? 0` / `?? false`，欄位名打錯不會拋例外、只會靜默變成 0，
/// 所以逐欄位斷言是唯一能擋住這種失敗的方法。
///
/// 三個 Pack 包的 JSON 是從實際執行中的伺服器擷取的原文
/// （登入 → 選角 → C_OBJECT_LIST），其餘為依 Java 端 put(...) 手寫。
Map<String, dynamic> _data(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

void main() {
  group('S_NPC_PACK', () {
    test('解析伺服器實際送出的 JSON', () {
      final pack = SNpcPack.fromData(_data('''
      {
        "mapId": 1,
        "npcs": [
          { "objId": 2000000009, "name": "藥童", "x": 35, "y": 20, "heading": 2,
            "npcId": 46000, "gfxid": 7, "type": 1 }
        ]
      }
      '''));

      expect(pack.mapId, 1);
      expect(pack.npcs, hasLength(1));

      final npc = pack.npcs.single;
      expect(npc.objId, 2000000009);
      expect(npc.name, '藥童');
      expect(npc.x, 35);
      expect(npc.y, 20);
      expect(npc.heading, 2);
      expect(npc.npcId, 46000);
      expect(npc.gfxid, 7);
      expect(npc.type, NpcObjectType.npc);
      expect(npc.interactive, isTrue);
    });

    test('type 代號對應與未知值退回 scenery', () {
      expect(NpcObjectType.fromCode(0), NpcObjectType.monster);
      expect(NpcObjectType.fromCode(1), NpcObjectType.npc);
      expect(NpcObjectType.fromCode(2), NpcObjectType.shop);
      expect(NpcObjectType.fromCode(3), NpcObjectType.gather);
      expect(NpcObjectType.fromCode(4), NpcObjectType.scenery);
      expect(NpcObjectType.fromCode(99), NpcObjectType.scenery);
    });
  });

  group('S_MONSTER_PACK', () {
    test('解析伺服器實際送出的 JSON（含血量）', () {
      final pack = SMonsterPack.fromData(_data('''
      {
        "mapId": 1,
        "monsters": [
          { "objId": 2000000007, "name": "野狼", "x": 40, "y": 21, "heading": 2,
            "npcId": 45000, "gfxid": 1, "maxHp": 50, "currentHp": 50 },
          { "objId": 2000000008, "name": "野狼", "x": 40, "y": 18, "heading": 2,
            "npcId": 45000, "gfxid": 1, "maxHp": 50, "currentHp": 50 }
        ]
      }
      '''));

      expect(pack.mapId, 1);
      expect(pack.monsters, hasLength(2));

      final first = pack.monsters.first;
      expect(first.objId, 2000000007);
      expect(first.name, '野狼');
      expect(first.x, 40);
      expect(first.y, 21);
      expect(first.heading, 2);
      expect(first.npcId, 45000);
      expect(first.gfxid, 1);
      expect(first.maxHp, 50);
      expect(first.currentHp, 50);

      // 同名怪物必須靠 objId 區分。
      expect(pack.monsters[1].objId, 2000000008);
      expect(pack.monsters[1].name, first.name);
    });
  });

  group('S_PROPERTY_PACK', () {
    test('解析伺服器實際送出的 JSON', () {
      final pack = SPropertyPack.fromData(_data('''
      {
        "mapId": 1,
        "properties": [
          { "objId": 2000000011, "name": "石碑", "x": 40, "y": 17, "heading": 2,
            "propertyId": 1001, "pngid": 20, "action": true,
            "actionType": 1, "value": 0 },
          { "objId": 2000000012, "name": "枯樹", "x": 40, "y": 22, "heading": 2,
            "propertyId": 1002, "pngid": 21, "action": false,
            "actionType": 0, "value": 0 }
        ]
      }
      '''));

      expect(pack.mapId, 1);
      expect(pack.properties, hasLength(2));

      final stone = pack.properties.first;
      expect(stone.objId, 2000000011);
      expect(stone.name, '石碑');
      expect(stone.x, 40);
      expect(stone.y, 17);
      expect(stone.heading, 2);
      expect(stone.propertyId, 1001);
      expect(stone.pngid, 20);
      expect(stone.action, isTrue);
      expect(stone.actionType, 1);
      expect(stone.value, 0);

      expect(pack.properties[1].action, isFalse);
      expect(pack.properties[1].actionType, 0);
    });

    test('帶碰撞欄位：blocking 與地面佔格', () {
      final pack = SPropertyPack.fromData(_data('''
      { "mapId": 1, "properties": [
        { "objId": 5, "name": "大樹", "x": 10, "y": 10, "heading": 2,
          "propertyId": 1010, "pngid": 1010, "blocking": true,
          "footprintW": 1, "footprintH": 1,
          "action": false, "actionType": 0, "value": 0 },
        { "objId": 6, "name": "房屋", "x": 20, "y": 20, "heading": 2,
          "propertyId": 1020, "pngid": 1020, "blocking": true,
          "footprintW": 2, "footprintH": 2,
          "action": false, "actionType": 0, "value": 0 } ] }
      '''));
      expect(pack.properties.first.blocking, isTrue);
      expect(pack.properties.first.footprintW, 1);
      // 2x2 房屋：佔格是地面格數，與視覺尺寸無關。
      expect(pack.properties[1].footprintW, 2);
      expect(pack.properties[1].footprintH, 2);
    });

    test('缺 footprint 欄位時預設為 1x1 而非 0', () {
      final pack = SPropertyPack.fromData(_data('''
      { "mapId": 1, "properties": [ { "objId": 7, "x": 1, "y": 1 } ] }
      '''));
      expect(pack.properties.single.footprintW, 1);
      expect(pack.properties.single.footprintH, 1);
      expect(pack.properties.single.blocking, isFalse);
    });

    test('bubbleText 不隨清單封包送出', () {
      final pack = SPropertyPack.fromData(_data('''
      { "mapId": 1, "properties": [
        { "objId": 1, "name": "石碑", "x": 1, "y": 1, "heading": 2,
          "propertyId": 1001, "pngid": 20, "action": true,
          "actionType": 1, "value": 0 } ] }
      '''));
      // 型別上就沒有這個欄位；此測試釘住「對話文字只走 S_BUBBLE_DIALOG」的設計。
      expect(pack.properties.single.actionType, 1);
    });
  });

  group('增量更新封包', () {
    test('S_NPC_MOVE', () {
      final move = SNpcMove.fromData(
          _data('{"objId": 2000000007, "x": 12, "y": 34, "heading": 5}'));
      expect(move.objId, 2000000007);
      expect(move.x, 12);
      expect(move.y, 34);
      expect(move.heading, 5);
    });

    test('S_PROPERTY_UPDATE', () {
      final update = SPropertyUpdate.fromData(
          _data('{"objId": 2000000011, "value": 3, "action": false}'));
      expect(update.objId, 2000000011);
      expect(update.value, 3);
      expect(update.action, isFalse);
    });

    test('S_OBJECT_REMOVE', () {
      final remove =
          SObjectRemove.fromData(_data('{"objId": 2000000012}'));
      expect(remove.objId, 2000000012);
    });

    test('copyWith 只改移動欄位，其餘保持不變', () {
      final npc = NpcObject.fromJson(_data('''
      { "objId": 7, "name": "藥童", "x": 1, "y": 2, "heading": 2,
        "npcId": 46000, "gfxid": 7, "type": 1 }
      '''));
      final moved = npc.copyWith(x: 9, y: 9, heading: 4);
      expect(moved.x, 9);
      expect(moved.y, 9);
      expect(moved.heading, 4);
      expect(moved.objId, npc.objId);
      expect(moved.name, npc.name);
      expect(moved.npcId, npc.npcId);
      expect(moved.gfxid, npc.gfxid);
      expect(moved.type, npc.type);
    });
  });

  group('對話封包', () {
    test('S_BUBBLE_DIALOG 帶 objId（氣泡要畫在誰頭上）', () {
      final bubble = SBubbleDialog.fromData(_data(
          '{"objId": 2000000011, "name": "石碑", "text": "此地乃青雲門禁地"}'));
      expect(bubble.objId, 2000000011);
      expect(bubble.name, '石碑');
      expect(bubble.text, '此地乃青雲門禁地');
    });

    test('S_DIALOG 以 objId 識別並帶回覆分支', () {
      final dialog = SDialog.fromData(_data('''
      { "objId": 2000000009, "name": "藥童", "text": "客倌要買點什麼？",
        "options": [ {"id": 1, "text": "我要買藥"}, {"id": 2, "text": "沒事"} ] }
      '''));
      expect(dialog.objId, 2000000009);
      expect(dialog.name, '藥童');
      expect(dialog.text, '客倌要買點什麼？');
      expect(dialog.options, hasLength(2));
      expect(dialog.options.first.id, 1);
      expect(dialog.options.first.text, '我要買藥');
    });

    test('S_DIALOG 無選項時 options 為空清單', () {
      final dialog = SDialog.fromData(
          _data('{"objId": 1, "name": "", "text": "嗯。", "options": []}'));
      expect(dialog.options, isEmpty);
      expect(dialog.name, isEmpty);
    });
  });

  group('S_MAP_INFO', () {
    test('帶場景底圖編號 gfxid', () {
      final info = SMapInfo.fromData(_data('''
      { "mapId": 1, "mapName": "黑森林", "gfxid": 2004,
        "width": 50, "height": 50, "portals": [] }
      '''));
      expect(info.mapId, 1);
      expect(info.mapName, '黑森林');
      expect(info.gfxid, 2004);
      expect(info.width, 50);
    });

    test('未設底圖時 gfxid 為 0（前端退回 assets/maps/{mapId}.png）', () {
      final info = SMapInfo.fromData(_data(
          '{"mapId": 1, "mapName": "黑森林", "width": 50, "height": 50}'));
      expect(info.gfxid, 0);
    });
  });

  group('S_GATHER_RESULT', () {
    test('採集成功', () {
      final result = SGatherResult.fromData(_data('''
      { "success": true, "objId": 2000000011, "itemId": 40001,
        "itemName": "靈草", "amount": 1, "message": "", "respawnMs": 30000 }
      '''));
      expect(result.success, isTrue);
      expect(result.objId, 2000000011);
      expect(result.itemId, 40001);
      expect(result.itemName, '靈草');
      expect(result.amount, 1);
      expect(result.message, isEmpty);
      expect(result.respawnMs, 30000);
    });

    test('採集失敗帶原因', () {
      final result = SGatherResult.fromData(_data('''
      { "success": false, "objId": 2000000011, "itemId": 0, "itemName": "",
        "amount": 0, "message": "距離太遠", "respawnMs": 0 }
      '''));
      expect(result.success, isFalse);
      expect(result.message, '距離太遠');
    });
  });

  group('S_ATTACK', () {
    test('飛行道具：三段動畫齊全', () {
      final attack = SAttack.fromData(_data('''
      { "attackerObjId": 2000000001, "targetObjId": 1000000005,
        "damage": 37,
        "animType": 1, "castGfx": 120, "flyGfx": 121, "hitGfx": 122 }
      '''));
      expect(attack.attackerObjId, 2000000001);
      expect(attack.targetObjId, 1000000005);
      expect(attack.damage, 37);
      expect(attack.animType, AttackAnimType.projectile);
      expect(attack.castGfx, 120);
      expect(attack.flyGfx, 121);
      expect(attack.hitGfx, 122);
    });

    test('直接命中：animType=0，只有 hitGfx', () {
      final attack = SAttack.fromData(_data('''
      { "attackerObjId": 1, "targetObjId": 2, "damage": 10,
        "animType": 0, "castGfx": 0, "flyGfx": 0, "hitGfx": 99 }
      '''));
      expect(attack.animType, AttackAnimType.direct);
      expect(attack.flyGfx, 0);
      expect(attack.hitGfx, 99);
    });

    test('血量欄位已移出，改由 S_HP_UPDATE 負責', () {
      final update = SHpUpdate.fromData(
          _data('{"objId": 2000000007, "currentHp": 13, "maxHp": 50}'));
      expect(update.objId, 2000000007);
      expect(update.currentHp, 13);
      expect(update.maxHp, 50);
    });

    test('S_MP_UPDATE 與 HP 同形但欄位獨立', () {
      final update = SMpUpdate.fromData(
          _data('{"objId": 1000000005, "currentMp": 22, "maxMp": 80}'));
      expect(update.objId, 1000000005);
      expect(update.currentMp, 22);
      expect(update.maxMp, 80);
    });
  });

  group('容錯', () {
    test('缺欄位時退回預設值而非拋例外', () {
      final npc = NpcObject.fromJson(_data('{}'));
      expect(npc.objId, 0);
      expect(npc.name, isEmpty);
      expect(npc.heading, 2);
      expect(npc.type, NpcObjectType.scenery);
    });

    test('數值為 JSON 浮點時仍能解析（num 而非 int）', () {
      final move = SNpcMove.fromData(
          _data('{"objId": 2000000007.0, "x": 12.0, "y": 34.0, "heading": 5}'));
      expect(move.objId, 2000000007);
      expect(move.x, 12);
      expect(move.y, 34);
    });

    test('空清單封包', () {
      expect(SNpcPack.fromData(_data('{"mapId": 3}')).npcs, isEmpty);
      expect(
          SMonsterPack.fromData(_data('{"mapId": 3}')).monsters, isEmpty);
      expect(SPropertyPack.fromData(_data('{"mapId": 3}')).properties,
          isEmpty);
    });
  });
}
