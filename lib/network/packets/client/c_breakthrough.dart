import '../../opcodes/client_opcodes.dart';

class CBreakthrough {
  CBreakthrough._();

  static Map<String, dynamic> build() {
    return {
      'op': ClientOpcodes.cBreakthrough,
      'data': const {},
    };
  }
}
