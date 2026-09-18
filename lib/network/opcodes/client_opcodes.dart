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
  static const cEnterPortal = 'C_ENTER_PORTAL'; // 進入傳送點（換圖，帶 portalId + facing）
  static const cMapInfo = 'C_MAP_INFO'; // 請求地圖資訊（小地圖：地名 + 傳送點）
  static const cChat = 'C_CHAT'; // 聊天發言（頻道 + 內容 + 私聊對象）
  static const cPlaceProperty = 'C_PLACE_PROPERTY'; // 放置家具（洞府布置）
  static const cRemoveProperty = 'C_REMOVE_PROPERTY'; // 移除家具
  static const cPlaceableList = 'C_PLACEABLE_LIST'; // 請求可放置家具清單
  static const cMoveProperty = 'C_MOVE_PROPERTY'; // 搬動已放置的家具
  static const cGmCollision = 'C_GM_COLLISION'; // GM 編輯地形碰撞（單格切換）
  static const cUseItem = 'C_USE_ITEM'; // 使用道具
  static const cDropItem = 'C_DROP_ITEM'; // 丟棄道具
  static const cAttack = 'C_ATTACK'; // 攻擊目標
  static const cParty = 'C_PARTY'; // 隊伍操作（invite/accept/decline/leave/kick/promote）
  static const cChallenge = 'C_CHALLENGE'; // 秘境挑戰進出（enter/leave）
  static const cGmCommand = 'C_GM_COMMAND'; // GM 指令（不含前綴的指令原文）
  static const cObjectList = 'C_OBJECT_LIST'; // 請求地圖物件清單（NPC／怪物／採集點／場景）
}
