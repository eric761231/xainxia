import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/opcodes/client_opcodes.dart';
import 'package:xianxia_game/network/packets/client/c_gm_command.dart';
import 'package:xianxia_game/network/packets/server/s_gm_result.dart';

/// GM 指令的前綴剝除很容易出錯：若把 '.' 也一起送出去，
/// 伺服器會收到 ".tp 1" 而找不到名為 ".tp" 的指令，錯誤訊息又很像打錯字，
/// 難以察覺是前端的問題。
void main() {
  test('C_GM_COMMAND 只帶不含前綴的指令原文', () {
    final packet = CGmCommand.build(command: 'tp 1 40 40');
    expect(packet['op'], ClientOpcodes.cGmCommand);
    expect(packet['data'], {'command': 'tp 1 40 40'});
  });

  test('S_GM_RESULT 解析成功與失敗', () {
    final ok = SGmResult.fromData(
        {'success': true, 'message': '已從地圖 0 傳送至 黑森林(1) (40,40)'});
    expect(ok.success, isTrue);
    expect(ok.message, contains('黑森林'));

    final bad = SGmResult.fromData({'success': false, 'message': '權限不足'});
    expect(bad.success, isFalse);
    expect(bad.message, '權限不足');
  });

  test('缺欄位時不拋例外', () {
    final r = SGmResult.fromData({});
    expect(r.success, isFalse);
    expect(r.message, isEmpty);
  });

  test('多行訊息（.help）能逐行拆開', () {
    const help = '可用 GM 指令：\n  .tp <地圖編號> [x] [y] － 傳送\n  .help － 說明';
    final r = SGmResult.fromData({'success': true, 'message': help});
    final lines =
        r.message.split('\n').where((l) => l.trim().isNotEmpty).toList();
    expect(lines, hasLength(3));
    expect(lines.first, '可用 GM 指令：');
  });
}
