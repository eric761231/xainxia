import '../../opcodes/client_opcodes.dart';

class CCharList {
  CCharList._();

  static Map<String, dynamic> build() {
    return {
      'op': ClientOpcodes.cCharList,
      'data': <String, dynamic>{},
    };
  }
}
