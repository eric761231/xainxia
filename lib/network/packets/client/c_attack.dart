import '../../opcodes/client_opcodes.dart';

/// 攻擊目標。
///
/// 只送出「意圖」—— 距離、目標是否可攻擊、是否還活著，全部由伺服器判定。
/// 與移動同樣的分工：前端先擋一次只是省往返，不是授權。
class CAttack {
  CAttack._();

  static Map<String, dynamic> build({required int targetObjId}) => {
        'op': ClientOpcodes.cAttack,
        'data': {'targetObjId': targetObjId},
      };
}
