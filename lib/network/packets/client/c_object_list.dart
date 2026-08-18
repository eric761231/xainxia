import '../../opcodes/client_opcodes.dart';

/// 地圖物件清單請求封包。
///
/// 伺服器依角色當前所在地圖回 [SObjectList]。
/// 進圖後或斷線重連需要重建地圖物件時送出。
class CObjectList {
  CObjectList._();

  static Map<String, dynamic> build() => {
        'op': ClientOpcodes.cObjectList,
        'data': <String, dynamic>{},
      };
}
