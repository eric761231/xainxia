package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

public class S_LogoutResult extends ServerBasePacket {

    private S_LogoutResult(boolean success, String message) {
        super(ServerOpcodes.S_LOGOUT_RESULT);
        put("success", success);
        put("message", message != null ? message : "");
    }

    public static S_LogoutResult ok() {
        return new S_LogoutResult(true, "登出成功");
    }

    public static S_LogoutResult fail(String message) {
        return new S_LogoutResult(false, message != null ? message : "登出失敗");
    }
}
