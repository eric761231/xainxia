import '../../opcodes/client_opcodes.dart';

/// 使用道具。以 objId 指定哪一筆（同種道具可能有多筆）。
class CUseItem {
  CUseItem._();

  static Map<String, dynamic> build({required int objId}) => {
        'op': ClientOpcodes.cUseItem,
        'data': {'objId': objId},
      };
}

/// 丟棄道具。目前是直接銷毀，不會在地上生成可撿的物件。
class CDropItem {
  CDropItem._();

  static Map<String, dynamic> build({required int objId, int count = 1}) => {
        'op': ClientOpcodes.cDropItem,
        'data': {'objId': objId, 'count': count},
      };
}
