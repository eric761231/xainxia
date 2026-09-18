import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/packets/server/s_map_tiles.dart';

/// S_MAP_TILES 的解析。
///
/// 這支釘住的是**前後端對格式的共識**。伺服器送 `[x, y, 圖磚編號]`，
/// 座標就是遊戲座標（31..50），編號要配 `tiles` 對照表才知道是哪張圖 ——
/// 任一邊理解不同，地面就會鋪錯或整片空白，而且不會拋例外。
void main() {
  Map<String, dynamic> packet({
    List<dynamic>? ground,
    Map<String, dynamic>? tiles,
    String tileDir = 'ground',
  }) =>
      {
        'mapId': 0,
        'tileWidth': 64,
        'tileHeight': 32,
        'walkMin': 31,
        'walkMax': 33,
        'tileDir': tileDir,
        'tiles': tiles ??
            {
              '1': 'brick_light_1.png',
              '8': 'brick_mid_1.png',
              '16': 'brick_dark_5.png',
            },
        'ground': ground ??
            [
              [31, 31, 1],
              [32, 31, 8],
              [33, 31, 16],
              [31, 32, 8],
            ],
      };

  group('解析', () {
    test('座標就是遊戲座標，不必再換算', () {
      final t = SMapTiles.fromData(packet());
      expect(t.walkMin, 31);
      expect(t.walkMax, 33);
      expect(t.ground.first, (31, 31, 1));
      expect(t.ground.last, (31, 32, 8));
    });

    test('圖磚對照表的鍵轉成數字', () {
      final t = SMapTiles.fromData(packet());
      expect(t.tiles[1], 'brick_light_1.png');
      expect(t.tiles[16], 'brick_dark_5.png');
      expect(t.tiles.length, 3);
    });

    test('沒列到的格子就是不鋪 —— ground 只有列出來的那些', () {
      // 舊格式要為每個空格寫 0；現在直接不寫
      expect(SMapTiles.fromData(packet()).ground, hasLength(4));
    });
  });

  group('圖磚路徑', () {
    test('接上子資料夾', () {
      final t = SMapTiles.fromData(packet());
      expect(t.pathFor(1), 'ground/brick_light_1.png');
      expect(t.pathFor(16), 'ground/brick_dark_5.png');
    });

    test('沒有子資料夾時直接用檔名', () {
      final t = SMapTiles.fromData(packet(tileDir: ''));
      expect(t.pathFor(1), 'brick_light_1.png');
    });

    test('編號不在對照表裡回 null（該格不鋪，不是崩潰）', () {
      expect(SMapTiles.fromData(packet()).pathFor(99), isNull);
    });
  });

  group('容錯', () {
    test('缺欄位時退回預設而非拋例外', () {
      final t = SMapTiles.fromData({});
      expect(t.tileWidth, 64);
      expect(t.tiles, isEmpty);
      expect(t.ground, isEmpty);
      expect(t.isValid, isFalse);
    });

    test('壞掉的格子略過，其餘照常 —— 一格壞不該讓整片地面消失', () {
      final t = SMapTiles.fromData(packet(ground: [
        [31, 31, 1],
        [32, 31],       // 少一個欄位
        'x',            // 根本不是陣列
        [33, 31, 16],
      ]));
      expect(t.ground, [(31, 31, 1), (33, 31, 16)]);
    });

    test('沒有圖磚或沒有地面時 isValid 為 false（呼叫端據此略過）', () {
      expect(SMapTiles.fromData(packet(ground: [])).isValid, isFalse);
      expect(SMapTiles.fromData(packet(tiles: {})).isValid, isFalse);
    });
  });
}
