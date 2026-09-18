import '../../opcodes/client_opcodes.dart';

/// GM 指令封包。
///
/// [command] 為<b>不含前綴</b>的指令原文（例：`tp 1 40 40`）——
/// 前端負責剝除開頭的 `.`，伺服器只認純指令。
/// 所有 GM 指令共用這一個封包，新增指令不需要新增封包。
class CGmCommand {
  CGmCommand._();

  static Map<String, dynamic> build({required String command}) => {
        'op': ClientOpcodes.cGmCommand,
        'data': {'command': command},
      };
}
