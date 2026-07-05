import '../../opcodes/client_opcodes.dart';

/// 客戶端登入請求封包（C = Client 發出）。
///
/// 透過 [build] 組出 JSON 後，交給 [GameSocket.send] 送往伺服器。
/// 伺服器回應 [SLoginResult]（op: S_LOGIN_RESULT）。
class CAuthLogin {
  // 私有建構子：此類別只提供靜態 build，不允許直接 new。
  CAuthLogin._();

  /// 組裝登入封包 JSON。
  ///
  /// 回傳格式：{ "op": "C_AUTH_LOGIN", "data": { "account": "...", "password": "..." } }
  static Map<String, dynamic> build({
    required String account,
    required String password,
  }) {
    return {
      'op': ClientOpcodes.cAuthLogin,
      'data': {
        // 帳號統一轉小寫，避免大小寫不同導致伺服器比對失敗。
        'account': account.toLowerCase(),
        'password': password,
      },
    };
  }
}
