import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/packets/server/s_wave.dart';

/// 波次狀態的解析與顯示規則。
///
/// 重點是 `breakLeft` 的語意：它只在**這一波清完之後**才有值。
/// 戰鬥進行中如果 breakLeft > 0，HUD 會顯示「下一波 N」而不是「剩餘 N」——
/// 實測踩過這個，伺服器原本在生怪時就把倒數設好了。
void main() {
  SWave wave({int w = 1, int alive = 3, int breakLeft = 0}) =>
      SWave.fromData({'wave': w, 'alive': alive, 'breakLeft': breakLeft});

  group('狀態判讀', () {
    test('戰鬥中：有波次、有剩餘、不在倒數', () {
      final w = wave(alive: 3, breakLeft: 0);
      expect(w.isActive, isTrue);
      expect(w.isResting, isFalse, reason: '戰鬥中不該顯示倒數');
    });

    test('清完後：剩餘 0、倒數中', () {
      final w = wave(alive: 0, breakLeft: 8);
      expect(w.isResting, isTrue);
      expect(w.alive, 0);
    });

    test('尚未開始：wave 0 不顯示', () {
      // 沒有波次的地圖不該掛著戰鬥資訊
      expect(wave(w: 0).isActive, isFalse);
    });
  });

  group('容錯', () {
    test('缺欄位時退回 0 而非拋例外', () {
      final w = SWave.fromData({});
      expect(w.wave, 0);
      expect(w.alive, 0);
      expect(w.breakLeft, 0);
      expect(w.isActive, isFalse);
    });
  });
}
