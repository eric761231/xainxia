import '../../opcodes/client_opcodes.dart';

/// 客戶端伺服器列表請求（連 Gate 後發送，不需帳密）。
class CServerList {
  CServerList._();

  static Map<String, dynamic> build() {
    return {
      'op': ClientOpcodes.cServerList,
      'data': {},
    };
  }
}
