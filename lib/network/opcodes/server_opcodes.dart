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
  static const sLevelDownResult = 'S_LEVEL_DOWN_RESULT'; // 境界內降級結果
  static const sCharStatsUpdate = 'S_CHAR_STATS_UPDATE'; // 角色屬性完整更新
  static const sGatherResult = 'S_GATHER_RESULT'; // 採集結果（送給採集者本人）
  static const sDialog = 'S_DIALOG'; // NPC 對話視窗（含回覆分支）
  static const sBubbleDialog = 'S_BUBBLE_DIALOG'; // 氣泡對話（顯示於物件頭上）
  static const sAttack = 'S_ATTACK'; // 攻擊演出（傷害數字 + 動畫）
  static const sHpUpdate = 'S_HP_UPDATE'; // 血量更新（自己／隊友／怪物血條）
  static const sMpUpdate = 'S_MP_UPDATE'; // 法力更新（自己與隊友）
  static const sMapChange = 'S_MAP_CHANGE'; // 換圖／傳送結果（含到達地圖/座標/面向）
  static const sMapInfo = 'S_MAP_INFO'; // 地圖資訊（小地圖：地名 + 尺寸 + 傳送點）
  static const sNpcPack = 'S_NPC_PACK'; // NPC 清單（NPC／商店／採集物／場景 NPC）
  static const sMonsterPack = 'S_MONSTER_PACK'; // 怪物清單（含血量）
  static const sPropertyPack = 'S_PROPERTY_PACK'; // 場景物件清單
  static const sNpcMove = 'S_NPC_MOVE'; // NPC／怪物移動廣播
  static const sPropertyUpdate = 'S_PROPERTY_UPDATE'; // 場景物件狀態變化（採集進度）
  static const sObjectRemove = 'S_OBJECT_REMOVE'; // 通用物件移除（採集耗盡／怪物死亡）
  static const sChat = 'S_CHAT'; // 聊天訊息（含系統訊息）
  static const sMapList = 'S_MAP_LIST'; // 地圖清單（GM 面板傳送用）
  static const sPlaceableList = 'S_PLACEABLE_LIST'; // 可放置家具清單
  static const sMapCollision = 'S_MAP_COLLISION'; // 地圖地形碰撞格（GM 編輯後廣播）
  static const sMapTiles = 'S_MAP_TILES'; // 地圖圖磚：哪個座標用哪一張圖
  static const sInventory = 'S_INVENTORY'; // 整份背包（進遊戲時送一次）
  static const sItemUpdate = 'S_ITEM_UPDATE'; // 單一道具新增或變更（upsert）
  static const sItemRemove = 'S_ITEM_REMOVE'; // 道具從背包消失
  static const sParty = 'S_PARTY'; // 隊伍狀態（整包重送）
  static const sPartyInvite = 'S_PARTY_INVITE'; // 收到組隊邀請
  static const sWave = 'S_WAVE'; // 波次狀態（每秒廣播）
  static const sGameOver = 'S_GAME_OVER'; // 挑戰結算（死亡時送，角色同時被送回洞府）
  static const sPcPack = 'S_PC_PACK'; // 同圖的其他玩家（整包重送）
  static const sGmResult = 'S_GM_RESULT'; // GM 指令執行結果
  static const sServerShutdown = 'S_SERVER_SHUTDOWN'; // 伺服器關閉（收到後關閉遊戲視窗）
}
