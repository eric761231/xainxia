import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_object_catalog.dart';

void main() {
  test('IsoMapData toJson ↔ fromJson round-trip 保持資料一致', () {
    const src = '''
    {
      "id": "7",
      "name": "測試村",
      "width": 3,
      "height": 2,
      "tileWidth": 64,
      "tileHeight": 32,
      "background": "center_room.png",
      "originX": -512,
      "originY": -260.5,
      "tilesets": [
        {"firstId": 1, "image": "ground.png", "tileWidth": 64, "tileHeight": 32, "columns": 8,
         "marginX": 4, "marginY": 70, "spacing": 2}
      ],
      "layers": [
        {"type": "tiles", "name": "ground", "data": [[1,2,3],[4,0,6]]},
        {"type": "collision", "name": "collision", "data": [[1,0,1],[0,0,1]]}
      ],
      "exits": [
        {"x": 2, "y": 0, "toMap": 5, "toX": 3, "toY": 4}
      ],
      "interactables": [
        {"x": 1, "y": 1, "type": "portal", "label": "樓梯", "toMap": 9, "toX": 2, "toY": 3},
        {"x": 0, "y": 1, "type": "gather", "label": "靈芝", "resourceId": "herb_01"},
        {"x": 2, "y": 1, "type": "talk", "label": "守衛", "npcId": 42},
        {"x": 0, "y": 0, "type": "attack", "label": "妖獸", "targetId": 777}
      ]
    }
    ''';

    final a = IsoMapData.fromJson(jsonDecode(src) as Map<String, dynamic>);
    // 序列化再解析
    final b = IsoMapData.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);

    expect(b.id, a.id);
    expect(b.name, a.name);
    expect(b.width, a.width);
    expect(b.height, a.height);
    expect(b.tileWidth, a.tileWidth);
    expect(b.tileHeight, a.tileHeight);
    expect(b.background, 'center_room.png');
    expect(b.hasBackground, isTrue);
    expect(b.originX, -512);
    expect(b.originY, -260.5);
    expect(b.tilesets.length, a.tilesets.length);
    expect(b.tilesets.first.firstId, 1);
    expect(b.tilesets.first.image, 'ground.png');
    expect(b.tilesets.first.columns, 8);
    // tileset 切片參數 round-trip
    expect(b.tilesets.first.marginX, 4);
    expect(b.tilesets.first.marginY, 70);
    expect(b.tilesets.first.spacing, 2);
    // srcRect：第 0 格含 margin；第 9 格（第2列第1欄）含 margin + spacing。
    final ts = b.tilesets.first;
    expect(ts.srcRect(0), const Rect.fromLTWH(4, 70, 64, 32));
    expect(ts.srcRect(9), const Rect.fromLTWH(4 + 1 * (64 + 2),
        70 + 1 * (32 + 2), 64, 32));
    // 預設值省略時不輸出（保持舊地圖 JSON 不變）。
    const plain =
        IsoTileset(firstId: 1, image: 'g.png', tileWidth: 64, tileHeight: 32, columns: 4);
    expect(plain.toJson().containsKey('marginX'), isFalse);
    expect(plain.toJson().containsKey('marginY'), isFalse);
    expect(plain.toJson().containsKey('spacing'), isFalse);
    expect(b.layers.length, 2);
    expect(b.layers.first.name, 'ground');
    expect(b.layers.first.type, 'tiles');
    expect(b.layers.first.data, [
      [1, 2, 3],
      [4, 0, 6],
    ]);
    // 具體格值抽查
    expect(b.layers.first.tileAt(0, 0), 1);
    expect(b.layers.first.tileAt(2, 1), 6);
    expect(b.layers.first.tileAt(1, 1), 0);

    // 碰撞層 + isBlocked
    expect(b.collisionLayer, isNotNull);
    expect(b.collisionLayer!.type, 'collision');
    expect(b.isBlocked(0, 0), isTrue); // data[0][0]=1
    expect(b.isBlocked(2, 1), isTrue); // data[1][2]=1
    expect(b.isBlocked(1, 0), isFalse); // data[0][1]=0
    expect(b.isBlocked(99, 99), isFalse); // 界外

    // 出口 + exitAt
    expect(b.exits.length, 1);
    final e = b.exitAt(2, 0);
    expect(e, isNotNull);
    expect(e!.toMap, 5);
    expect(e.toX, 3);
    expect(e.toY, 4);
    expect(b.exitAt(0, 0), isNull); // 非出口格

    // 互動物件 + interactableAt
    expect(b.interactables.length, 4);
    expect(b.portals.length, 1);

    final portal = b.interactableAt(1, 1);
    expect(portal, isNotNull);
    expect(portal!.kind, InteractKind.portal);
    expect(portal.label, '樓梯');
    expect(portal.toMap, 9);
    expect(portal.toX, 2);
    expect(portal.toY, 3);

    final gather = b.interactableAt(0, 1);
    expect(gather!.kind, InteractKind.gather);
    expect(gather.resourceId, 'herb_01');

    final talk = b.interactableAt(2, 1);
    expect(talk!.kind, InteractKind.talk);
    expect(talk.npcId, 42);

    final attack = b.interactableAt(0, 0);
    expect(attack!.kind, InteractKind.attack);
    expect(attack.targetId, 777);

    expect(b.interactableAt(5, 5), isNull); // 非互動格
  });

  test('物件層（objects）round-trip：解析、與 tile 層分流、toJson 復原', () {
    const src = '''
    {
      "id": "0",
      "name": "梅花村",
      "width": 16, "height": 16, "tileWidth": 64, "tileHeight": 32,
      "tilesets": [],
      "layers": [
        {"type": "tiles", "name": "ground", "data": [[1,1],[1,1]]},
        {"type": "objects", "name": "props", "objects": [
          {"id": 1001, "x": 5, "y": 5},
          {"id": 1002, "x": 10, "y": 6, "zBias": 3}
        ]}
      ]
    }
    ''';

    final a = IsoMapData.fromJson(jsonDecode(src) as Map<String, dynamic>);
    // 物件層被分流到 objects，不混進 tile layers。
    expect(a.layers.length, 1);
    expect(a.layers.first.type, 'tiles');
    expect(a.objects.length, 2);
    expect(a.objects[0].id, 1001);
    expect(a.objects[0].x, 5);
    expect(a.objects[0].y, 5);
    expect(a.objects[0].zBias, 0);
    expect(a.objects[1].zBias, 3);

    // 序列化再解析後一致。
    final b = IsoMapData.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
    expect(b.layers.length, 1);
    expect(b.objects.length, 2);
    expect(b.objects[1].id, 1002);
    expect(b.objects[1].x, 10);
    expect(b.objects[1].y, 6);
    expect(b.objects[1].zBias, 3);
  });

  test('ObjectDef.fromJson：atlas 明確 src/anchor 解析', () {
    final tree = ObjectDef.fromJson(1002, {
      'image': 'trees.png',
      'src': [0, 0, 128, 192],
      'anchor': [64, 180],
      'footprint': [1, 1],
      'blocking': true,
      'label': '樹',
    });
    expect(tree.image, 'trees.png');
    expect(tree.srcW, 128);
    expect(tree.srcH, 192);
    expect(tree.anchorX, 64);
    expect(tree.anchorY, 180);
    expect(tree.blocking, isTrue);
    expect(tree.footprintW, 1);
    expect(tree.label, '樹');
  });

  test('ObjectDef.fromJson：一檔一物件（省略 src/anchor → null，渲染端依圖尺寸解析）', () {
    // 省略 src → srcW/srcH 為 null（整張圖）；省略 anchor → anchorX/Y 為 null（底邊中央）。
    final treeWhole = ObjectDef.fromJson(1010, {
      'image': 'tree001.png',
      'blocking': true,
      'label': '樹一',
    });
    expect(treeWhole.srcW, isNull);
    expect(treeWhole.srcH, isNull);
    expect(treeWhole.anchorX, isNull);
    expect(treeWhole.anchorY, isNull);
    expect(treeWhole.srcX, 0);
    expect(treeWhole.srcY, 0);
    expect(treeWhole.blocking, isTrue);
    expect(treeWhole.footprintW, 1);
    expect(treeWhole.footprintH, 1);

    // 房屋：footprint 指定、blocking；仍走整張圖（src/anchor 省略）。
    final house = ObjectDef.fromJson(1020, {
      'image': 'house025.png',
      'footprint': [2, 2],
      'blocking': true,
    });
    expect(house.srcW, isNull);
    expect(house.footprintW, 2);
    expect(house.footprintH, 2);
    expect(house.blocking, isTrue);

    // 花：blocking 省略 → false。
    final flower = ObjectDef.fromJson(1001, {'image': 'flowers001.png'});
    expect(flower.blocking, isFalse);
    expect(flower.footprintW, 1);
  });

  test('ObjectDef.resolveAnchor：foot/center/明確 anchor 優先', () {
    // 預設 foot：底邊中央 (w/2, h)。
    final foot = ObjectDef.fromJson(1010, {'image': 'tree001.png'});
    expect(foot.anchorMode, 'foot');
    expect(foot.resolveAnchor(100, 200), (50.0, 200.0));

    // center：圖中央 (w/2, h/2)。
    final center =
        ObjectDef.fromJson(1001, {'image': 'flowers001.png', 'anchorMode': 'center'});
    expect(center.anchorMode, 'center');
    expect(center.resolveAnchor(100, 200), (50.0, 100.0));

    // tile：等距地形，anchorY = mapHalfTileHeight（頂點對齊格頂點）。
    final tile = ObjectDef.fromJson(3001, {'image': 't.png', 'anchorMode': 'tile'});
    expect(tile.anchorMode, 'tile');
    expect(tile.resolveAnchor(576, 288, mapHalfTileHeight: 16), (288.0, 16.0));

    // 明確 anchor 優先於 anchorMode。
    final explicit = ObjectDef.fromJson(1002, {
      'image': 'x.png',
      'src': [0, 0, 128, 192],
      'anchor': [64, 180],
      'anchorMode': 'center',
    });
    expect(explicit.resolveAnchor(128, 192), (64.0, 180.0));
  });

  test('MapObject offsetX/Y round-trip（省略時不輸出）', () {
    final a = MapObject.fromJson({'id': 1010, 'x': 3, 'y': 4, 'offsetX': -6, 'offsetY': 8});
    expect(a.offsetX, -6);
    expect(a.offsetY, 8);
    final j = a.toJson();
    expect(j['offsetX'], -6);
    expect(j['offsetY'], 8);

    // 無 offset → 不輸出 key。
    final b = MapObject.fromJson({'id': 1, 'x': 0, 'y': 0});
    expect(b.offsetX, 0);
    expect(b.toJson().containsKey('offsetX'), isFalse);
    expect(b.toJson().containsKey('offsetY'), isFalse);
  });

  test('ObjectDef.dir 解析：objects(預設)/sences/tiles/非法→objects', () {
    expect(ObjectDef.fromJson(1, {'image': 'a.png'}).dir, 'objects');
    expect(
        ObjectDef.fromJson(2, {'image': 'a.png', 'dir': 'sences'}).dir, 'sences');
    expect(
        ObjectDef.fromJson(3, {'image': 'a.png', 'dir': 'tiles'}).dir, 'tiles');
    expect(ObjectDef.fromJson(4, {'image': 'a.png', 'dir': '???'}).dir,
        'objects');
  });

  test('MapObject tilesW round-trip（0 省略）', () {
    final a = MapObject.fromJson({'id': 3001, 'x': 2, 'y': 2, 'tilesW': 4});
    expect(a.tilesW, 4);
    expect(a.toJson()['tilesW'], 4);

    final b = MapObject.fromJson({'id': 1, 'x': 0, 'y': 0});
    expect(b.tilesW, 0);
    expect(b.toJson().containsKey('tilesW'), isFalse);
  });

  test('MapObject.layer round-trip（預設1省略）', () {
    final a = MapObject.fromJson({'id': 1, 'x': 0, 'y': 0, 'layer': 3});
    expect(a.layer, 3);
    expect(a.toJson()['layer'], 3);

    final b = MapObject.fromJson({'id': 1, 'x': 0, 'y': 0});
    expect(b.layer, 1);
    expect(b.toJson().containsKey('layer'), isFalse);
  });

  test('IsoMapData.objectLayers/characterLayer round-trip（預設1省略）', () {
    const src = '''
    {
      "id": "9", "name": "多層圖", "width": 4, "height": 4,
      "tileWidth": 64, "tileHeight": 32, "tilesets": [],
      "objectLayers": 3, "characterLayer": 2,
      "layers": [
        {"type": "objects", "name": "props", "objects": [
          {"id": 3001, "x": 1, "y": 1, "layer": 1},
          {"id": 1010, "x": 1, "y": 1, "layer": 2}
        ]}
      ]
    }
    ''';
    final a = IsoMapData.fromJson(jsonDecode(src) as Map<String, dynamic>);
    expect(a.objectLayers, 3);
    expect(a.characterLayer, 2);
    expect(a.objects.where((o) => o.x == 1 && o.y == 1).length, 2); // 同格疊兩層

    final b = IsoMapData.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
    expect(b.objectLayers, 3);
    expect(b.characterLayer, 2);
    expect(b.objects.firstWhere((o) => o.id == 3001).layer, 1);
    expect(b.objects.firstWhere((o) => o.id == 1010).layer, 2);

    // 預設值不輸出。
    final plain = IsoMapData.fromJson(
        jsonDecode('{"id":"0","name":"x","width":1,"height":1,"tilesets":[],"layers":[]}')
            as Map<String, dynamic>);
    expect(plain.objectLayers, 1);
    expect(plain.characterLayer, 1);
    expect(plain.toJson().containsKey('objectLayers'), isFalse);
    expect(plain.toJson().containsKey('characterLayer'), isFalse);
  });
}
