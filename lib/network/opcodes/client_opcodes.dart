class ClientOpcodes {
  ClientOpcodes._();

  static const cServerList = 'C_SERVER_LIST'; // 伺服器列表請求
  static const cAuthLogin = 'C_AUTH_LOGIN'; // 登入請求
  static const cAuthLogout = 'C_AUTH_LOGOUT'; // 登出請求
  static const cCharList = 'C_CHAR_LIST'; // 角色列表請求
  static const cCreateChar = 'C_CREATE_CHAR'; // 創建角色請求
  static const cDeleteChar = 'C_DELETE_CHAR'; // 刪除角色請求
  static const cSelectChar = 'C_SELECT_CHAR'; // 選擇角色請求
  static const cKeepAlive = 'C_KEEP_ALIVE'; // 心跳包
  static const cMove = 'C_MOVE'; // 人物移動
  static const cFace = 'C_FACE'; // 人物轉向（不移動）
  static const cBreakthrough = 'C_BREAKTHROUGH'; // 嘗試境界突破
  static const cGainExp = 'C_GAIN_EXP'; // 獲得經驗值
}
