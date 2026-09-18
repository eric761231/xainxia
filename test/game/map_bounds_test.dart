import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';
import 'package:xianxia_game/network/packets/server/s_map_tiles.dart';

/// 地圖大小的唯一來源是伺服器的 map 表。
///
/// 前端若停在 onLoad 那份 31..50 的底版，把地圖改大之後的症狀是
/// **玩家走到舊邊界就停住**，而且沒有任何錯誤訊息 —— 圖磚寫到陣列外、
/// 碰撞陣列不會跟著長、clamp 把人鎖住。這組測試盯的就是那個。
void main() {
  group('IsoMapData 依邊界建格網', () {
    test('20×20（31..50）', () {
      final d = IsoMapData.generic(minCoord: 31, maxCoord: 50, mapId: 0);
      expect(d.walkMinCoord, 31);
      expect(d.walkMaxCoord, 50);
      expect(d.walkSize, 20);
      // 可走區外再留一圈不可走邊界，所以陣列是 20 + 2
      expect(d.width, 22);
      expect(d.coordOffset, 30);
    });

    test('放大到 60×60（31..90）時陣列與換算都跟著長', () {
      final d = IsoMapData.generic(minCoord: 31, maxCoord: 90, mapId: 1);
      expect(d.walkSize, 60);
      expect(d.width, 62);
      // 這是先前會壞掉的地方：座標 90 在舊的 22 格陣列裡是索引 60，越界
      expect(d.toIndex(90), 60);
      expect(d.toIndex(90), lessThan(d.width));
      // 玩家的 clamp 上限要跟著放大，否則走到 51 就停住
      expect(d.maxMapCoordX, greaterThanOrEqualTo(90));
    });

    test('格子尺寸也要跟著伺服器 —— 寫死 64×32 會讓地板散開', () {
      // 這是實際踩到的 bug：圖磚是 48×24，但格網用預設的 64×32 畫，
      // 間距比圖大三分之一，每一格之間漏出底色，整片地板變成碎片。
      final d = IsoMapData.generic(
        minCoord: 31, maxCoord: 90, mapId: 1, tileWidth: 48, tileHeight: 24);
      expect(d.tileWidth, 48);
      expect(d.tileHeight, 24);
      expect(d.halfTileWidth, 24);
      expect(d.halfTileHeight, 12);
      // 2:1 必須維持，否則 26.565° 的等距投影就不成立
      expect(d.tileWidth / d.tileHeight, 2.0);
    });

    test('每一格座標都落在陣列內（放大後最容易漏的邊界）', () {
      final d = IsoMapData.generic(minCoord: 31, maxCoord: 90, mapId: 1);
      for (final c in [31, 50, 51, 89, 90]) {
        final i = d.toIndex(c);
        expect(i, inInclusiveRange(0, d.width - 1), reason: '座標 $c → 索引 $i 越界');
      }
    });
  });

  group('S_MAP_TILES 帶著邊界', () {
    test('walkMin/walkMax 有被解析出來 —— 重建格網要靠它', () {
      final t = SMapTiles.fromData(const {
        'mapId': 1,
        'tileWidth': 48,
        'tileHeight': 24,
        'walkMin': 31,
        'walkMax': 90,
        'tileDir': 'black_forest',
        'tiles': {'1': 'grass_moss.png'},
        'ground': [[31, 31, 1], [90, 90, 1]],
      });
      expect(t.isValid, isTrue);
      expect(t.walkMin, 31);
      expect(t.walkMax, 90);
      expect(t.tileWidth, 48);
      expect(t.tileHeight, 24);
    });
  });
}
