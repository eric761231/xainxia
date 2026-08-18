package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

public class S_CharacterAmount extends ServerBasePacket {

    public S_CharacterAmount(int count, int maxSlots) {
        super(ServerOpcodes.S_CHARACTER_AMOUNT);
        put("count", count);
        put("maxSlots", maxSlots);
    }
}
