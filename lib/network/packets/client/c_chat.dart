import '../../opcodes/client_opcodes.dart';
import '../server/s_chat.dart';

/// 聊天發言封包。
///
/// [target] 僅 [ChatChannel.whisper] 需要；其餘頻道送空字串。
/// 綜合與系統頻道不可發送（伺服器會拒絕並回系統訊息）。
class CChat {
  CChat._();

  static Map<String, dynamic> build({
    required ChatChannel channel,
    required String text,
    String target = '',
  }) =>
      {
        'op': ClientOpcodes.cChat,
        'data': {
          'channel': channel.code,
          'text': text,
          'target': target,
        },
      };
}
