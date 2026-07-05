import '../../opcodes/client_opcodes.dart';

/// 人物轉向封包（不移動，僅改變面向）。
/// facing 0-7：NE/E/SE/S/SW/W/NW/N（畫面方向順時針）。
class CFace {
  CFace._();

  static Map<String, dynamic> build({required int facing}) => {
        'op': ClientOpcodes.cFace,
        'data': {'facing': facing},
      };
}
