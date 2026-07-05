import '../../opcodes/client_opcodes.dart';

class CGainExp {
  CGainExp._();

  static Map<String, dynamic> build({required int amount}) => {
        'op': ClientOpcodes.cGainExp,
        'data': {'amount': amount},
      };
}
