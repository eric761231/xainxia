import '../../opcodes/client_opcodes.dart';

class CCreateChar {
  CCreateChar._();

  static Map<String, dynamic> build({
    required String name,
    required int sex,
    required int attribute,
    required int statsIntel,
    required int statsSpirit,
    required int statsAgility,
    required int statsConstitution,
  }) {
    return {
      'op': ClientOpcodes.cCreateChar,
      'data': {
        'name': name,
        'sex': sex,
        'attribute': attribute,
        'statsIntel': statsIntel,
        'statsSpirit': statsSpirit,
        'statsAgility': statsAgility,
        'statsConstitution': statsConstitution,
      },
    };
  }
}
