import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_coord.dart';

/// 投影是**明確宣告**的，不從格尺寸推。這幾個測試把兩種投影的往返釘住。
///
/// 背景：專案原本只有 2:1 等距；改成也支援俯視之後，全專案有 17 個
/// 呼叫點會用到投影。那些呼叫點已經統一走 `IsoMapData` 的包裝方法，
/// 但包裝底下的這一層仍是唯一的真相來源，值得單獨驗。
void main() {
  const halfW = 32.0; // 等距 64x32
  const halfH = 16.0;

  group('等距', () {
    test('格 → 螢幕：回菱形頂點', () {
      final p = IsoCoord.tileToScreen(1, 0, halfW, halfH);
      expect(p.x, 32.0);
      expect(p.y, 16.0);
    });

    test('往返：格內任何一點都映回同一格', () {
      for (final t in [(0, 0), (3, 5), (12, 7)]) {
        final sp = IsoCoord.tileToScreen(t.$1, t.$2, halfW, halfH);
        // 取菱形中心（頂點往下 halfH）
        final mid = Vector2(sp.x, sp.y + halfH);
        expect(IsoCoord.screenToTile(mid, halfW, halfH), (t.$1, t.$2));
      }
    });

    test('四個角是菱形：上、右、下、左', () {
      final c = IsoCoord.cellCorners(0, 0, halfW, halfH);
      expect(c[0], Vector2(0, 0));
      expect(c[1], Vector2(halfW, halfH));
      expect(c[2], Vector2(0, halfH * 2));
      expect(c[3], Vector2(-halfW, halfH));
    });
  });

  group('俯視', () {
    const sq = 24.0; // 48x48 的正方格

    test('格 → 螢幕：回方格上緣中點', () {
      final p = IsoCoord.tileToScreen(2, 3, sq, sq,
          projection: MapProjection.topDown);
      // 第 2 欄的左緣在 2*48=96，上緣中點 x = 96+24
      expect(p.x, 120.0);
      expect(p.y, 144.0);
    });

    test('往返：格內任何一點都映回同一格', () {
      for (final t in [(0, 0), (3, 5), (12, 7)]) {
        final sp = IsoCoord.tileToScreen(t.$1, t.$2, sq, sq,
            projection: MapProjection.topDown);
        final mid = Vector2(sp.x, sp.y + sq);
        expect(
            IsoCoord.screenToTile(mid, sq, sq,
                projection: MapProjection.topDown),
            (t.$1, t.$2));
      }
    });

    test('四個角是方格，且與貼圖用的外接矩形一致', () {
      final c = IsoCoord.cellCorners(120, 144, sq, sq,
          projection: MapProjection.topDown);
      expect(c[0], Vector2(96, 144));
      expect(c[1], Vector2(144, 144));
      expect(c[2], Vector2(144, 192));
      expect(c[3], Vector2(96, 192));
    });

    test('相鄰格不重疊也不留縫', () {
      final a = IsoCoord.tileToScreen(0, 0, sq, sq,
          projection: MapProjection.topDown);
      final b = IsoCoord.tileToScreen(1, 0, sq, sq,
          projection: MapProjection.topDown);
      // 兩格的上緣中點相距正好一格寬
      expect(b.x - a.x, sq * 2);
    });
  });
}
