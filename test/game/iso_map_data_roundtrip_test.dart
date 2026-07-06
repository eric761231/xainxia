import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';

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
      "tilesets": [
        {"firstId": 1, "image": "ground.png", "tileWidth": 64, "tileHeight": 32, "columns": 8}
      ],
      "layers": [
        {"type": "tiles", "name": "ground", "data": [[1,2,3],[4,0,6]]}
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
    expect(b.tilesets.length, a.tilesets.length);
    expect(b.tilesets.first.firstId, 1);
    expect(b.tilesets.first.image, 'ground.png');
    expect(b.tilesets.first.columns, 8);
    expect(b.layers.length, 1);
    expect(b.layers.first.name, 'ground');
    expect(b.layers.first.data, [
      [1, 2, 3],
      [4, 0, 6],
    ]);
    // 具體格值抽查
    expect(b.layers.first.tileAt(0, 0), 1);
    expect(b.layers.first.tileAt(2, 1), 6);
    expect(b.layers.first.tileAt(1, 1), 0);
  });
}
