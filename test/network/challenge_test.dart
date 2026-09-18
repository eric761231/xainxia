import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/opcodes/client_opcodes.dart';
import 'package:xianxia_game/network/packets/client/c_challenge.dart';
import 'package:xianxia_game/network/packets/server/s_attack.dart';
import 'package:xianxia_game/network/packets/server/s_game_over.dart';

/// 秘境挑戰的封包對接。
///
/// 這些欄位名稱是前後端唯一的契約 —— 打錯不會拋例外，只會安靜地讀到 0，
/// 結算畫面就會顯示「第 0 波、擊殺 0」而看不出原因。
void main() {
  group('C_CHALLENGE', () {
    test('動作字串與伺服器的 switch 一致', () {
      expect(CChallenge.enter()['op'], ClientOpcodes.cChallenge);
      expect((CChallenge.enter()['data'] as Map)['action'], 'enter');
      expect((CChallenge.leave()['data'] as Map)['action'], 'leave');
    });
  });

  group('S_GAME_OVER', () {
    test('欄位解析', () {
      final r = SGameOver.fromData(
          const {'wave': 5, 'kills': 23, 'seconds': 142});
      expect(r.wave, 5);
      expect(r.kills, 23);
      expect(r.seconds, 142);
    });

    test('存活時間格式化為 分:秒', () {
      expect(SGameOver.fromData(const {'seconds': 142}).survivedText, '2:22');
      expect(SGameOver.fromData(const {'seconds': 7}).survivedText, '0:07');
      expect(SGameOver.fromData(const {}).survivedText, '0:00');
    });
  });

  group('S_ATTACK 的命中欄位', () {
    test('未命中時 hit 為 false、傷害為 0', () {
      final a = SAttack.fromData(const {
        'attackerObjId': 1,
        'targetObjId': 2,
        'damage': 0,
        'hit': false,
      });
      expect(a.hit, isFalse);
      expect(a.damage, 0);
    });

    test('缺少 hit 欄位時視為命中（相容舊版伺服器）', () {
      expect(SAttack.fromData(const {'damage': 7}).hit, isTrue);
    });
  });
}
