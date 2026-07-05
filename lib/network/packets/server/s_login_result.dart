/// 伺服器登入結果封包（S = Server 回傳）。
///
/// 對應 opcode [ServerOpcodes.sLoginResult]（S_LOGIN_RESULT）。
/// 登入成功時 [success] 為 true，並附帶帳號、權限、伺服器資訊；
/// 失敗時 [reason] 為數字代碼，可透過 [message] 取得中文說明。
class SLoginResult {
  const SLoginResult({
    required this.success,
    required this.reason,
    this.account,
    this.accessLevel,
    this.serverNo,
    this.serverName,
  });

  // --- 伺服器 reason 代碼（與後端協定一致，勿隨意修改） ---

  static const reasonLoginOk = 0;
  static const reasonPassCheck = 10;
  static const reasonAccountInUse = 22;
  static const reasonMaxPlayer = 39;
  static const reasonAccountBan = 93;

  /// 是否登入成功。
  final bool success;

  /// 結果代碼；失敗時用於判斷原因，見上方常數。
  final int reason;

  /// 登入成功後的帳號名稱。
  final String? account;

  /// 帳號權限等級（GM 等）。
  final int? accessLevel;

  /// 所屬伺服器編號。
  final int? serverNo;

  /// 所屬伺服器名稱。
  final String? serverName;

  /// 從 [GamePacket.data] 解析為強型別物件。
  ///
  /// [data] 為伺服器 JSON 的 data 欄位；缺欄位時使用安全預設值。
  factory SLoginResult.fromData(Map<String, dynamic> data) {
    return SLoginResult(
      success: data['success'] as bool? ?? false,
      reason: data['reason'] as int? ?? reasonPassCheck,
      account: data['account'] as String?,
      accessLevel: data['accessLevel'] as int?,
      serverNo: data['serverNo'] as int?,
      serverName: data['serverName'] as String?,
    );
  }

  /// 將 [reason] 代碼轉成使用者可讀的中文訊息。
  String get message {
    switch (reason) {
      case reasonLoginOk:
        return '登入成功';
      case reasonPassCheck:
        return '帳號或密碼錯誤';
      case reasonAccountInUse:
        return '帳號已在使用中';
      case reasonMaxPlayer:
        return '伺服器人數已滿';
      case reasonAccountBan:
        return '帳號已被封鎖';
      default:
        return '登入失敗（代碼 $reason）';
    }
  }
}
