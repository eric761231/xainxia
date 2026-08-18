package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

public class S_DeleteCharResult extends ServerBasePacket {

    public static final String REASON_OK = "OK";
    public static final String REASON_NOT_FOUND = "NOT_FOUND";
    public static final String REASON_DB_ERROR = "DB_ERROR";

    private S_DeleteCharResult(boolean success, String reason, String message) {
        super(ServerOpcodes.S_DELETE_CHAR_RESULT);
        put("success", success);
        put("reason", reason);
        put("message", message);
    }

    public static S_DeleteCharResult ok() {
        return new S_DeleteCharResult(true, REASON_OK, "角色刪除成功");
    }

    public static S_DeleteCharResult fail(String reason, String message) {
        return new S_DeleteCharResult(false, reason, message);
    }
}
