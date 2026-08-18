package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 創角結果回應。
 */
public class S_CreateCharResult extends ServerBasePacket {

    public static final String REASON_OK = "OK";
    public static final String REASON_INVALID_NAME = "INVALID_NAME";
    public static final String REASON_NAME_EXISTS = "NAME_EXISTS";
    public static final String REASON_SLOT_FULL = "SLOT_FULL";
    public static final String REASON_INVALID_SEX = "INVALID_SEX";
    public static final String REASON_INVALID_ATTRIBUTE = "INVALID_ATTRIBUTE";
    public static final String REASON_INVALID_STATS = "INVALID_STATS";
    public static final String REASON_DB_ERROR = "DB_ERROR";
    public static final String REASON_NOT_AUTHENTICATED = "NOT_AUTHENTICATED";

    private S_CreateCharResult(boolean success, String reason, String message) {
        super(ServerOpcodes.S_CREATE_CHAR_RESULT);
        put("success", success);
        put("reason", reason);
        put("message", message);
    }

    public static S_CreateCharResult ok() {
        return new S_CreateCharResult(true, REASON_OK, "角色建立成功");
    }

    public static S_CreateCharResult fail(String reason, String message) {
        return new S_CreateCharResult(false, reason, message);
    }
}
