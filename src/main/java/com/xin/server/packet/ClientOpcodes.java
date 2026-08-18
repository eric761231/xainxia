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

}
