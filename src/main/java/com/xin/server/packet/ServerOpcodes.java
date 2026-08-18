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

    /** 地圖物件清單（NPC／怪物／採集點／場景物件） */
    public static final String S_OBJECT_LIST = "S_OBJECT_LIST";

    /** 伺服器關閉通知（客戶端收到後關閉遊戲視窗） */
    public static final String S_SERVER_SHUTDOWN = "S_SERVER_SHUTDOWN";
}
