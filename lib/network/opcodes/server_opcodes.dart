class ServerOpcodes {
  ServerOpcodes._();

  static const sServerList = 'S_SERVER_LIST'; // 伺服器列表
  static const sLoginResult = 'S_LOGIN_RESULT'; // 登入結果
  static const sLogoutResult = 'S_LOGOUT_RESULT'; // 登出結果
  static const sCharacterList = 'S_CHARACTER_LIST'; // 角色列表
  static const sCharacterAmount = 'S_CHARACTER_AMOUNT'; // 角色數量
  static const sEnterGame = 'S_ENTER_GAME'; // 進入遊戲世界
  static const sCreateCharResult = 'S_CREATE_CHAR_RESULT'; // 創角結果
  static const sDeleteCharResult = 'S_DELETE_CHAR_RESULT'; // 刪角結果
  static const sSystemMessage = 'S_SYSTEM_MESSAGE'; // 系統訊息
  static const sCharMove = 'S_CHAR_MOVE'; // 人物移動廣播
  static const sCharFace = 'S_CHAR_FACE'; // 人物轉向廣播
  static const sBreakthroughResult = 'S_BREAKTHROUGH_RESULT'; // 境界突破結果
  static const sLevelUpResult = 'S_LEVEL_UP_RESULT'; // 境界內升級結果
  static const sCharStatsUpdate = 'S_CHAR_STATS_UPDATE'; // 角色屬性完整更新
  static const sGatherResult = 'S_GATHER_RESULT'; // 採集結果
  static const sDialog = 'S_DIALOG'; // NPC 對話內容
  static const sCombatResult = 'S_COMBAT_RESULT'; // 戰鬥／技能結果
  static const sMapChange = 'S_MAP_CHANGE'; // 換圖／傳送結果（含到達地圖/座標/面向）
  static const sMapInfo = 'S_MAP_INFO'; // 地圖資訊（小地圖：地名 + 尺寸 + 傳送點）
  static const sObjectList = 'S_OBJECT_LIST'; // 地圖物件清單（NPC／怪物／採集點／場景）
  static const sServerShutdown = 'S_SERVER_SHUTDOWN'; // 伺服器關閉（收到後關閉遊戲視窗）
}
