import '../../opcodes/client_opcodes.dart';

class CAuthLogout {
  CAuthLogout._();

  static Map<String, dynamic> build() {
    return {
      'op': ClientOpcodes.cAuthLogout,
      'data': <String, dynamic>{},
    };
  }
}
