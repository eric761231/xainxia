import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/iso_player_component.dart';

/// 人與多格家具的前後。
///
/// 家具的 priority 只看錨點（footprint 最前面那一格），人站在長書櫃側面時
/// 會被整個蓋住。前後改由格座標判斷。
void main() {
  group('depthRelation', () {
    // 靠左牆的 1×3 書櫃：x=1，y=2..4（錨點 (1,4)）
    const shelf = (1, 2, 1, 4);

    test('站在書櫃側面（x 較大）＝在前面，即使深度比錨點小', () {
      expect(IsoPlayerComponent.depthRelation([(2, 2)], shelf), 1);
      expect(IsoPlayerComponent.depthRelation([(2, 3)], shelf), 1);
    });

    test('站在書櫃後端再往後（y 較小）＝在後面', () {
      expect(IsoPlayerComponent.depthRelation([(1, 1)], shelf), -1);
    });

    test('太遠的家具不參與', () {
      expect(IsoPlayerComponent.depthRelation([(9, 9)], shelf), 0);
    });

    // 靠上牆的 2×1 櫃子：x=8..9，y=1（錨點 (9,1)）
    const cabinet = (8, 1, 9, 1);

    test('站在櫃子左側同一排（x 較小）＝在後面', () {
      expect(IsoPlayerComponent.depthRelation([(7, 1)], cabinet), -1);
    });

    test('站在櫃子前方＝在前面', () {
      expect(IsoPlayerComponent.depthRelation([(8, 2)], cabinet), 1);
    });

    test('走動中：出發格或目的格任一在前就算在前', () {
      expect(IsoPlayerComponent.depthRelation([(7, 1), (8, 2)], cabinet), 1);
    });
  });

  group('clampDepth', () {
    test('在前面的家具是下限', () {
      expect(IsoPlayerComponent.clampDepth(100, lower: 150), 151);
      expect(IsoPlayerComponent.clampDepth(200, lower: 150), 200);
    });

    test('在後面的家具是上限', () {
      expect(IsoPlayerComponent.clampDepth(200, upper: 150), 149);
      expect(IsoPlayerComponent.clampDepth(100, upper: 150), 100);
    });

    test('上下限矛盾時以在前面為準', () {
      expect(IsoPlayerComponent.clampDepth(100, lower: 150, upper: 120), 151);
    });
  });
}
