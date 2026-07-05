import '../../opcodes/client_opcodes.dart';

class CSelectChar {
  CSelectChar._();

  static Map<String, dynamic> build({required String name}) {
    return {
      'op': ClientOpcodes.cSelectChar,
      'data': {
        'name': name,
      },
    };
  }
}
