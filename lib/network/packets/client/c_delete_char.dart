import '../../opcodes/client_opcodes.dart';

class CDeleteChar {
  CDeleteChar._();

  static Map<String, dynamic> build({required String name}) {
    return {
      'op': ClientOpcodes.cDeleteChar,
      'data': {'name': name},
    };
  }
}
