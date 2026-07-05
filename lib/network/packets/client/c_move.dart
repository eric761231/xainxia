import '../../opcodes/client_opcodes.dart';

/// 人物移動封包。
/// facing 0-7：NE/E/SE/S/SW/W/NW/N（畫面方向順時針）。
class CMove {
  CMove._();

  static Map<String, dynamic> build({
    required int x,
    required int y,
    required int facing,
  }) =>
      {
        'op': ClientOpcodes.cMove,
        'data': {'x': x, 'y': y, 'facing': facing},
      };
}
