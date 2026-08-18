package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 人物移動廣播。
 */
public class S_CharMove extends ServerBasePacket {

    public S_CharMove(String charName, int x, int y, int heading) {
        super(ServerOpcodes.S_CHAR_MOVE);
        put("charName", charName);
        put("x", x);
        put("y", y);
        put("heading", heading);
    }
}
