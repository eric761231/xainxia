package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 伺服器關閉通知（對應 opcode {@code S_SERVER_SHUTDOWN}）。
 * <p>
 * 伺服器關閉前廣播給所有連線；客戶端收到後應關閉遊戲視窗。
 *
 * <pre>
 * { "op": "S_SERVER_SHUTDOWN", "data": { "message": "伺服器已關閉" } }
 * </pre>
 */
public class S_ServerShutdown extends ServerBasePacket {

    private S_ServerShutdown(String message) {
        super(ServerOpcodes.S_SERVER_SHUTDOWN);
        put("message", message);
    }

    public static S_ServerShutdown of(String message) {
        return new S_ServerShutdown(message);
    }
}
