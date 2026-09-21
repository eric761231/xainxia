package com.xin.server.packet;

/**
 * 客戶端封包操作碼（JSON op 欄位）
 */
public final class ClientOpcodes {

    private ClientOpcodes() {
    }
    
    /** 請求伺服器列表（Gate / CONNECTED 狀態） */
    public static final String C_SERVER_LIST = "C_SERVER_LIST";
    // ── 連線後 / CONNECTED ──
    /** 帳號密碼登入請求 */
    public static final String C_AUTH_LOGIN = "C_AUTH_LOGIN";

    /** 帳號登出（AUTHENTICATED / IN_GAME） */
    public static final String C_AUTH_LOGOUT = "C_AUTH_LOGOUT";
    
    // ── 登入成功後 / AUTHENTICATED ──
    /** 請求角色列表（對應天堂 C_CommonClick 進入選角） */
    public static final String C_CHAR_LIST   = "C_CHAR_LIST";
    /** 建立角色（對應天堂 C_NewChar） */
    public static final String C_CREATE_CHAR = "C_CREATE_CHAR";
    /** 刪除角色（對應天堂 C_DeleteChar） */
    public static final String C_DELETE_CHAR = "C_DELETE_CHAR";
    /** 選角進入遊戲（對應天堂 C_LoginToServer） */
    public static final String C_SELECT_CHAR = "C_SELECT_CHAR";
    
    // ── 遊戲中 / IN_GAME ──
    /** 心跳保活（對應天堂 C_KeepAlive） */
    public static final String C_KEEP_ALIVE  = "C_KEEP_ALIVE";
    /** 嘗試境界突破 */
    public static final String C_BREAKTHROUGH = "C_BREAKTHROUGH";
    /** 獲得經驗值 */
    public static final String C_GAIN_EXP = "C_GAIN_EXP";
    /** 人物移動 */
    public static final String C_MOVE = "C_MOVE";
    /** 人物轉向（不移動） */
    public static final String C_FACE = "C_FACE";
    /** 進入傳送點／換圖請求（伺服器查表決定目的地） */
    public static final String C_ENTER_PORTAL = "C_ENTER_PORTAL";
    /** 請求地圖資訊（小地圖：地名 + 傳送點清單） */
    public static final String C_MAP_INFO = "C_MAP_INFO";
    /** 請求地圖物件清單（NPC／怪物／採集點／場景物件） */
    public static final String C_OBJECT_LIST = "C_OBJECT_LIST";

    /** GM 指令（文字指令，伺服器端解析與分發） */
    public static final String C_GM_COMMAND = "C_GM_COMMAND";

    /** 聊天發言（頻道 + 內容，私聊另帶 target） */
    public static final String C_CHAT = "C_CHAT";

    /** 放置家具（洞府布置） */
    public static final String C_PLACE_PROPERTY = "C_PLACE_PROPERTY";

    /** 移除家具（洞府布置） */
    public static final String C_REMOVE_PROPERTY = "C_REMOVE_PROPERTY";

    /** 請求可放置家具清單 */
    public static final String C_PLACEABLE_LIST = "C_PLACEABLE_LIST";

    /** 搬動已放置的家具 */
    public static final String C_MOVE_PROPERTY = "C_MOVE_PROPERTY";

    /** GM 編輯地形碰撞（單格切換） */
    public static final String C_GM_COLLISION = "C_GM_COLLISION";

    /** 使用道具 */
    public static final String C_USE_ITEM = "C_USE_ITEM";

    /** 丟棄道具 */
    public static final String C_DROP_ITEM = "C_DROP_ITEM";

    /** 攻擊目標 */
    public static final String C_ATTACK = "C_ATTACK";

    /** 隊伍操作（invite／accept／decline／leave／kick／promote） */
    public static final String C_PARTY = "C_PARTY";

    /** 秘境挑戰進出（enter／leave） */
    public static final String C_CHALLENGE = "C_CHALLENGE";

}
