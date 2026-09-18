import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_map_component.dart';
import 'package:xianxia_game/game/map/iso_map_data.dart';

/// 底圖對齊的算式很容易差半格（16px），美術一旦照著錯的位置修圖就很難查回來，
/// 所以用實際數字釘死。
///
/// 另一個重點是「座標位移」：伺服器的地圖邊界不一定從 1 開始（B 方案是 31..50）。
/// 投影一律在陣列索引空間進行，所以不論邊界從幾開始，
/// 菱形與底圖都必須落在完全相同的位置。
void main() {
  group('1..20（無位移）', () {
    final data = IsoMapData.generic(minCoord: 1, maxCoord: 20);

    test('陣列涵蓋 0..21，可走 1..20', () {
      expect(data.coordOffset, 0);
      expect(data.width, 22);
      expect(data.walkMinCoord, 1);
      expect(data.walkMaxCoord, 20);
      expect(data.walkSize, 20);
    });

    test('底圖 1280 對齊可走區中心', () {
      final (x, y) = IsoMapComponent.backgroundOrigin(data, 1280, 1280);
      expect(x, -640.0);
      expect(y, -288.0); // 中心 352 - 半高 640
    });
  });

  group('31..50（B 方案，位移 30）', () {
    final data = IsoMapData.generic(minCoord: 31, maxCoord: 50);

    test('陣列只涵蓋實際範圍，不浪費前 30 排', () {
      expect(data.coordOffset, 30); // 索引 0 = 座標 30
      expect(data.width, 22); // 與 1..20 完全同尺寸
      expect(data.walkMinCoord, 31);
      expect(data.walkMaxCoord, 50);
      expect(data.walkSize, 20);
    });

    test('座標與索引互換', () {
      expect(data.toIndex(31), 1);
      expect(data.toIndex(50), 20);
      expect(data.toMapCoord(1), 31);
      expect(data.toMapCoord(20), 50);
    });

    test('可走區判定用地圖座標', () {
      expect(data.isBlocked(40, 40), isFalse); // 中心可走
      expect(data.isBlocked(31, 31), isFalse); // 邊角可走
      expect(data.isBlocked(50, 50), isFalse);
      expect(data.isBlocked(30, 40), isTrue); // 外圈邊界
      expect(data.isBlocked(51, 40), isTrue);
    });

    test('底圖原點與 1..20 完全相同 —— 位移不得影響畫面位置', () {
      final base = IsoMapComponent.backgroundOrigin(
          IsoMapData.generic(minCoord: 1, maxCoord: 20), 1280, 1280);
      final shifted = IsoMapComponent.backgroundOrigin(data, 1280, 1280);
      expect(shifted.$1, base.$1);
      expect(shifted.$2, base.$2);
      expect(shifted, (-640.0, -288.0));
    });

    test('上下留白相等且為邊長 ÷ 4', () {
      final (_, y) = IsoMapComponent.backgroundOrigin(data, 1280, 1280);
      const halfH = 16.0;
      final n = data.toIndex(data.walkMinCoord);
      final m = data.toIndex(data.walkMaxCoord);
      final diamondTop = 2 * n * halfH;
      final diamondBottom = 2 * m * halfH + 2 * halfH;
      expect(diamondTop - y, (y + 1280) - diamondBottom);
      expect(diamondTop - y, 320.0);
    });
  });

  group('繪製範圍必須等於可走區', () {
    // 外圈邊界只用於碰撞，不可被畫出來，否則菱形會比底圖每邊多一排。
    final data = IsoMapData.generic(minCoord: 31, maxCoord: 50);
    final ground =
        data.layers.firstWhere((l) => l.type != 'collision');

    test('ground 圖層在邊界格為 0（不繪製）', () {
      // 索引 0 與 21 是邊界（座標 30 與 51）
      expect(ground.tileAt(0, 0), 0);
      expect(ground.tileAt(21, 21), 0);
      expect(ground.tileAt(0, 10), 0);
      expect(ground.tileAt(10, 21), 0);
    });

    test('ground 圖層在可走區為 1（會繪製）', () {
      expect(ground.tileAt(1, 1), 1); // 座標 31,31
      expect(ground.tileAt(20, 20), 1); // 座標 50,50
      expect(ground.tileAt(10, 10), 1); // 座標 40,40
    });

    test('實際繪製的格數為 20x20，與 1280x640 菱形吻合', () {
      var drawn = 0;
      var minIx = 999, maxIx = -1;
      for (var y = 0; y < data.height; y++) {
        for (var x = 0; x < data.width; x++) {
          if (ground.tileAt(x, y) > 0) {
            drawn++;
            if (x < minIx) minIx = x;
            if (x > maxIx) maxIx = x;
          }
        }
      }
      expect(drawn, 400); // 20 x 20
      expect(minIx, 1);
      expect(maxIx, 20);
      // 菱形寬 = (maxIx - minIx + 1) * tileWidth
      expect((maxIx - minIx + 1) * data.tileWidth, 1280);
    });
  });

  group('map 0：牆面美術的轉角必須落在格網的 (31,31)', () {
    // 這組測試是為了一個實際發生過的錯位：S_MAP_TILES 到達時 _rebuildGrid 會把
    // 格網整份換掉（map 0 從 20x20@56 變成 10x10@112），但底圖原點當時是載入時
    // 算好存起來的，不會跟著更新 —— 畫面上就是牆與地板整個分離，偏移量剛好是
    // 新舊可走區中心的差（280px），而且沒有任何錯誤訊息。
    //
    // 數字來自 DrawPng/out/map0_wall_tiles/map0_wall_map0_layout.json：
    // 合成時把牆角釘在畫布的 (688, 315)，畫布 1376x1190。
    const bgW = 1376;
    const bgH = 1190;
    const cornerX = 688;
    const cornerY = 315;

    test('10x10 @112x56：牆角對上 tile(31,31) 的頂點', () {
      final data = IsoMapData.generic(
          minCoord: 31, maxCoord: 40, tileWidth: 112, tileHeight: 56);
      final (ox, oy) = IsoMapComponent.backgroundOrigin(data, bgW, bgH);
      // tileToScreen 吃的是陣列索引，不是世界座標（投影一律在索引空間進行）。
      final top = data.tileToScreen(data.toIndex(31), data.toIndex(31));
      expect(top.x - ox, cornerX.toDouble());
      expect(top.y - oy, cornerY.toDouble());
    });

    test('換格網之後原點必須跟著變，不能沿用舊值', () {
      // 進場時的底版是 31..50；伺服器送來 31..40 之後兩者的原點不同。
      // 若沿用底版算出來的原點，牆就會低 280px。
      final base = IsoMapData.generic(
          minCoord: 31, maxCoord: 50, tileWidth: 112, tileHeight: 56);
      final rebuilt = IsoMapData.generic(
          minCoord: 31, maxCoord: 40, tileWidth: 112, tileHeight: 56);
      final (_, baseY) = IsoMapComponent.backgroundOrigin(base, bgW, bgH);
      final (_, newY) = IsoMapComponent.backgroundOrigin(rebuilt, bgW, bgH);
      expect(baseY - newY, 280.0);
    });

    test('可走區菱形的寬度等於牆面的左右跨距', () {
      final data = IsoMapData.generic(
          minCoord: 31, maxCoord: 40, tileWidth: 112, tileHeight: 56);
      // 兩面牆各 10 格，每格水平 halfW；地板菱形寬 = 格數 x 格寬。
      expect(data.walkSize * data.tileWidth, 1120);
      expect(data.walkSize * 2 * data.halfTileWidth, 1120);
    });
  });
}
