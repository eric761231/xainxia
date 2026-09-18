import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/game/map/iso_object_catalog.dart';
import 'package:xianxia_game/game/map/iso_object_component.dart';

/// Mirrors XinServerProject/sql/map0_cave.sql.  Server collision
/// stamping uses the property anchor as the right-front cell and expands
/// backwards in both axes (see `iso_map_component.dart`: `tx = obj.x - i`).
class _Furniture {
  const _Furniture(this.id, this.x, this.y, this.width, this.height);

  final int id;
  final int x;
  final int y;
  final int width;
  final int height;

  Iterable<(int, int)> get cells sync* {
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        yield (x - dx, y - dy);
      }
    }
  }
}

/// 洞府布置：左牆兩座書櫃 + 白蘭花，後角松樹，右牆紅楓／靈石櫃／綠植。
/// 聚靈法陣（4107）是非阻擋地面 overlay，故不列入碰撞清單。
const _layout = [
  _Furniture(4103, 32, 32, 1, 1), // 松樹盆景（後方牆角）
  _Furniture(4104, 34, 31, 3, 1), // 紅楓長盆（右牆內段）
  _Furniture(4105, 39, 31, 2, 1), // 靈石竹簡櫃（右牆外段）
  _Furniture(4106, 40, 31, 1, 1), // 直立綠植（右牆末端）
  _Furniture(4101, 31, 34, 1, 3), // 洞府書櫃（左牆內段）
  _Furniture(4101, 31, 39, 1, 3), // 洞府書櫃（左牆外段）
  _Furniture(4102, 31, 40, 1, 1), // 白蘭花盆（左牆末端）
];

/// map 0 的可走範圍。格改成 112x56 之後房間是 10x10。
const _lo = 31;
const _hi = 40;

/// 左右牆各五個模組；格加倍之後一個模組是 2 格。窗戶在第三個模組。
/// local = world - 31，左牆沿 y、右牆沿 x。
const _leftWindowY = [35, 36]; // local 4..5
const _rightWindowX = [35, 36];

Set<(int, int)> _blocked() => {for (final item in _layout) ...item.cells};

bool _reachable((int, int) start, (int, int) goal, Set<(int, int)> blocked) {
  final seen = <(int, int)>{start};
  final queue = <(int, int)>[start];
  for (var index = 0; index < queue.length; index++) {
    final (x, y) = queue[index];
    if ((x, y) == goal) return true;
    for (final (nx, ny) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
      if (nx < _lo ||
          nx > _hi ||
          ny < _lo ||
          ny > _hi ||
          blocked.contains((nx, ny))) {
        continue;
      }
      if (seen.add((nx, ny))) queue.add((nx, ny));
    }
  }
  return false;
}

Map<String, dynamic> _catalogObjects() {
  final raw = File('assets/data/object_catalog.json').readAsStringSync();
  return (jsonDecode(raw) as Map<String, dynamic>)['objects']
      as Map<String, dynamic>;
}

void main() {
  test('map 0 家具：每個 footprint 無重疊，且每一格都會阻擋', () {
    final blocked = _blocked();
    final expectedCount = _layout.fold<int>(
      0,
      (sum, item) => sum + item.width * item.height,
    );
    expect(blocked.length, expectedCount, reason: '任兩件家具不得共用碰撞格');
    expect(blocked.length, 14);

    for (final item in _layout) {
      expect(
        item.cells.every(blocked.contains),
        isTrue,
        reason: 'property ${item.id} 的 footprint 必須全阻擋',
      );
    }
    expect(blocked.contains((_hi, _hi)), isFalse, reason: '入口格保持可走');
    expect(blocked.contains((35, 35)), isFalse, reason: '聚靈法陣本體保持可走');
  });

  test('map 0 家具：全部貼牆，中央修煉區完全淨空', () {
    final blocked = _blocked();
    // 格加倍之後家具只佔貼牆那一排（x=31 或 y=31），松樹是唯一的例外。
    for (final (x, y) in blocked) {
      expect(x == _lo || y == _lo || (x == 32 && y == 32), isTrue,
          reason: '($x,$y) 不貼牆，會擋到動線');
    }
    for (var x = 32; x <= _hi; x++) {
      for (var y = 33; y <= _hi; y++) {
        expect(blocked.contains((x, y)), isFalse,
            reason: '中央與前半場 ($x,$y) 必須淨空');
      }
    }
  });

  test('map 0 家具：兩面窗戶前的牆格沒有家具', () {
    final blocked = _blocked();
    for (final y in _leftWindowY) {
      expect(blocked.contains((_lo, y)), isFalse, reason: '左窗 (31,$y) 被遮住');
    }
    for (final x in _rightWindowX) {
      expect(blocked.contains((x, _lo)), isFalse, reason: '右窗 ($x,31) 被遮住');
    }
  });

  test('map 0 家具：入口到聚靈法陣有兩格寬的連續通道', () {
    final blocked = _blocked();
    expect(_reachable((_hi, _hi), (35, 35), blocked), isTrue);
    // 兩格寬：相鄰那條路線同樣走得通，通道不是單格縫隙。
    expect(_reachable((_hi - 1, _hi), (35, 36), blocked), isTrue);
  });

  test('object_catalog：洞府物件的圖檔存在，且 footprint 與 SQL 同值', () {
    final objects = _catalogObjects();
    final expected = {
      for (final item in _layout) item.id: (item.width, item.height),
    };
    for (final entry in expected.entries) {
      final raw = objects['${entry.key}'] as Map<String, dynamic>?;
      expect(raw, isNotNull, reason: 'catalog 缺少 ${entry.key}');
      final def = ObjectDef.fromJson(entry.key, raw!);
      expect((def.footprintW, def.footprintH), entry.value,
          reason: '${entry.key} 的 footprint 與伺服器 property 表不同');
      expect(def.blocking, isTrue);
      expect(File('assets/${def.dir}/${def.image}').existsSync(), isTrue,
          reason: '${entry.key} 的圖檔 ${def.image} 不存在');
    }
  });

  test('object_catalog：洞府物件使用原生像素，不以 tilesW 縮放', () {
    for (final id in const [4101, 4102, 4103, 4104, 4105, 4106, 4107]) {
      final raw = _catalogObjects()['$id'] as Map<String, dynamic>;
      expect(raw.containsKey('tilesW'), isFalse, reason: '$id 不可縮放原生素材');
    }

    // ObjectDef 的通用解析仍需保留小數 tilesW 支援。
    final probe = ObjectDef.fromJson(9999, const {
      'image': 'probe.png',
      'tilesW': 1.5,
    });
    expect(probe.tilesW, closeTo(1.5, 1e-9));
    expect(probe.tilesW.floor(), 1, reason: '確認 1.5 真的不是被四捨五入成 2');
  });

  test('object_catalog：洞府物件的錨點在圖內，且以腳底格中心為準', () {
    final objects = _catalogObjects();
    for (final id in const [4101, 4102, 4103, 4104, 4105, 4106, 4107]) {
      final def =
          ObjectDef.fromJson(id, objects['$id'] as Map<String, dynamic>);
      expect(def.anchorX, isNotNull, reason: '$id 必須有明確 anchor');
      expect(def.anchorY, isNotNull, reason: '$id 必須有明確 anchor');
      expect(def.anchorX!, greaterThanOrEqualTo(0));
      expect(def.anchorY!, greaterThan(0));
    }
  });

  test('接地陰影是地面上、玩家與家具本體下方的 sibling layer', () {
    final map = IsoMapData.fromJson({
      'id': '0',
      'name': 'map 0',
      'width': 20,
      'height': 20,
      'tileWidth': 64,
      'tileHeight': 32,
      'tilesets': [],
      'layers': [],
    });
    final shadow = IsoFootprintShadowComponent(
      def: ObjectDef.fromJson(4101, {
        'image': 'shelf.png',
        'footprint': [1, 3],
        'shadow': {
          'offsetTiles': [0, 0],
        },
      }),
      mapData: map,
      position: Vector2(640, 700),
      opacity: 1,
      layer: 1,
    );
    expect(shadow.priority, kLayerStride - 1);
    expect(shadow.priority, lessThan(map.characterLayer * kLayerStride));
  });
}
