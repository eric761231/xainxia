package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 人物轉向廣播。
 */
public class S_CharFace extends ServerBasePacket {

    public S_CharFace(String charName, int heading) {
        super(ServerOpcodes.S_CHAR_FACE);
        put("charName", charName);
        put("heading", heading);
    }
}
