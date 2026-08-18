package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 系統訊息封包
 */
public class S_SystemMessage extends ServerBasePacket {

    public S_SystemMessage(String message) {
        super(ServerOpcodes.S_SYSTEM_MESSAGE);
        put("message", message);
    }
}
