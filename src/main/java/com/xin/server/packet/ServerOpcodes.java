package com.xin.server.packet;

/**
 * 伺服器封包操作碼（JSON op 欄位）
 */
public final class ServerOpcodes {

    private ServerOpcodes() {
    }

    /** 登入結果回應 */
    public static final String S_LOGIN_RESULT = "S_LOGIN_RESULT";

    /** 登出結果回應 */
    public static final String S_LOGOUT_RESULT = "S_LOGOUT_RESULT";

    /** 角色列表 **/
    public static final String S_CHARACTER_LIST = "S_CHARACTER_LIST";
    
    /** 角色數量 **/
    public static final String S_CHARACTER_AMOUNT = "S_CHARACTER_AMOUNT";

    /** 進入遊戲世界 **/
    public static final String S_ENTER_GAME = "S_ENTER_GAME";

    /** 創角結果 **/
    public static final String S_CREATE_CHAR_RESULT = "S_CREATE_CHAR_RESULT";
    
    /** 伺服器列表 **/
    public static final String S_SERVER_LIST = "S_SERVER_LIST";
    
    /** 刪角結果 **/
    public static final String S_DELETE_CHAR_RESULT = "S_DELETE_CHAR_RESULT";

    /** 系統訊息 */
    public static final String S_SYSTEM_MESSAGE = "S_SYSTEM_MESSAGE";

    /** 境界突破結果 */
    public static final String S_BREAKTHROUGH_RESULT = "S_BREAKTHROUGH_RESULT";

    /** 境界內升級結果 */
    public static final String S_LEVEL_UP_RESULT = "S_LEVEL_UP_RESULT";

    /** 境界內降級結果 */
    public static final String S_LEVEL_DOWN_RESULT = "S_LEVEL_DOWN_RESULT";

    /** 角色屬性完整更新 */
    public static final String S_CHAR_STATS_UPDATE = "S_CHAR_STATS_UPDATE";

    /** 人物移動廣播 */
    public static final String S_CHAR_MOVE = "S_CHAR_MOVE";

    /** 人物轉向廣播 */
    public static final String S_CHAR_FACE = "S_CHAR_FACE";

    /** 換圖／傳送結果（含到達地圖/座標/面向） */
    public static final String S_MAP_CHANGE = "S_MAP_CHANGE";

    /** 地圖資訊（小地圖：地名 + 尺寸 + 傳送點清單） */
    public static final String S_MAP_INFO = "S_MAP_INFO";

    /** NPC 物件封包（NPC／商店／採集物／場景 NPC，不含怪物） */
    public static final String S_NPC_PACK = "S_NPC_PACK";

    /** 怪物物件封包（含血量） */
    public static final String S_MONSTER_PACK = "S_MONSTER_PACK";

    /** 場景物件封包（來自 property 表） */
    public static final String S_PROPERTY_PACK = "S_PROPERTY_PACK";

    /** 氣泡對話（互動場景物件時顯示於物件頭上） */
    public static final String S_BUBBLE_DIALOG = "S_BUBBLE_DIALOG";

    /** NPC／怪物移動廣播（兩者皆為 NpcInstance，共用同一包） */
    public static final String S_NPC_MOVE = "S_NPC_MOVE";

    /** 場景物件狀態變化（採集進度／是否還能互動） */
    public static final String S_PROPERTY_UPDATE = "S_PROPERTY_UPDATE";

    /** 通用物件移除（採集耗盡／怪物死亡／NPC 下線皆適用） */
    public static final String S_OBJECT_REMOVE = "S_OBJECT_REMOVE";

    /** 攻擊演出（傷害數字 + 動畫；血量另由 S_HP_UPDATE 更新） */
    public static final String S_ATTACK = "S_ATTACK";

    /** 血量更新（任何物件通用：怪物、玩家、隊友） */
    public static final String S_HP_UPDATE = "S_HP_UPDATE";

    /** 法力更新（自己與隊友；敵對目標不送） */
    public static final String S_MP_UPDATE = "S_MP_UPDATE";

    /** NPC 對話視窗（含可選的回覆分支） */
    public static final String S_DIALOG = "S_DIALOG";

    /** 採集結果（回應 C_GATHER，送給採集者本人） */
    public static final String S_GATHER_RESULT = "S_GATHER_RESULT";

    /** GM 指令執行結果（回饋給下指令的人） */
    public static final String S_GM_RESULT = "S_GM_RESULT";

    /** 聊天訊息（含系統訊息） */
    public static final String S_CHAT = "S_CHAT";

    /** 地圖清單（GM 面板傳送用） */
    public static final String S_MAP_LIST = "S_MAP_LIST";

    /** 可放置家具清單（洞府布置面板用） */
    public static final String S_PLACEABLE_LIST = "S_PLACEABLE_LIST";

    /** 地圖地形碰撞格（GM 編輯後廣播） */
    public static final String S_MAP_COLLISION = "S_MAP_COLLISION";

    /** 地圖圖磚：哪個座標用哪一張圖（進圖時送） */
    public static final String S_MAP_TILES = "S_MAP_TILES";

    /** 整份背包（進遊戲時送一次） */
    public static final String S_INVENTORY = "S_INVENTORY";

    /** 單一道具新增或變更（upsert 語意） */
    public static final String S_ITEM_UPDATE = "S_ITEM_UPDATE";

    /** 道具從背包消失 */
    public static final String S_ITEM_REMOVE = "S_ITEM_REMOVE";

    /** 隊伍狀態（任何變動都整包重送給全隊） */
    public static final String S_PARTY = "S_PARTY";

    /** 收到組隊邀請 */
    public static final String S_PARTY_INVITE = "S_PARTY_INVITE";

    /** 波次狀態（每秒廣播） */
    public static final String S_WAVE = "S_WAVE";

    /** 挑戰結算（死亡時送，角色同時被送回洞府） */
    public static final String S_GAME_OVER = "S_GAME_OVER";

    /** 同一張地圖上的其他玩家（整包重送，不做增量） */
    public static final String S_PC_PACK = "S_PC_PACK";

    /** 伺服器關閉通知（客戶端收到後關閉遊戲視窗） */
    public static final String S_SERVER_SHUTDOWN = "S_SERVER_SHUTDOWN";
}
