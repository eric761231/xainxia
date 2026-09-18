import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/packets/server/s_monster_pack.dart';

/// 釘住 Pack 包的 upsert 語意。
///
/// 三個 Pack 包同時服務兩種情境：進圖時的 N 筆初始化，以及之後單一物件
/// 出現時的 1 筆增量（天堂的 S_NPCPack 就是單一物件包）。
/// 若 handler 用「clear 後整包覆蓋」，1 筆的生怪包會清光整張圖的怪
/// —— 這正是本測試要防止的回歸。
Map<String, dynamic> _data(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

/// 與 MyGame 的容器更新邏輯等價的最小重現。
void applyPack(Map<int, MonsterObject> store, SMonsterPack pack) {
  store.addEntries(pack.monsters.map((m) => MapEntry(m.objId, m)));
}

void main() {
  final initial = SMonsterPack.fromData(_data('''
  { "mapId": 1, "monsters": [
    { "objId": 101, "name": "野狼", "x": 1, "y": 1, "heading": 2,
      "npcId": 45000, "gfxid": 1, "maxHp": 50, "currentHp": 50 },
    { "objId": 102, "name": "野狼", "x": 2, "y": 2, "heading": 2,
      "npcId": 45000, "gfxid": 1, "maxHp": 50, "currentHp": 50 } ] }
  '''));

  test('1 筆的即時生怪包不會清掉既有物件', () {
    final store = <int, MonsterObject>{};
    applyPack(store, initial);
    expect(store, hasLength(2));

    final spawn = SMonsterPack.fromData(_data('''
    { "mapId": 1, "monsters": [
      { "objId": 103, "name": "野豬", "x": 9, "y": 9, "heading": 2,
        "npcId": 45001, "gfxid": 2, "maxHp": 80, "currentHp": 80 } ] }
    '''));
    applyPack(store, spawn);

    expect(store, hasLength(3), reason: '生怪包不該清空整張圖');
    expect(store[101], isNotNull);
    expect(store[102], isNotNull);
    expect(store[103]!.name, '野豬');
  });

  test('相同 objId 再次送達時覆蓋而非重複', () {
    final store = <int, MonsterObject>{};
    applyPack(store, initial);

    final resend = SMonsterPack.fromData(_data('''
    { "mapId": 1, "monsters": [
      { "objId": 101, "name": "野狼", "x": 7, "y": 7, "heading": 4,
        "npcId": 45000, "gfxid": 1, "maxHp": 50, "currentHp": 12 } ] }
    '''));
    applyPack(store, resend);

    expect(store, hasLength(2));
    expect(store[101]!.x, 7);
    expect(store[101]!.currentHp, 12);
  });
}
