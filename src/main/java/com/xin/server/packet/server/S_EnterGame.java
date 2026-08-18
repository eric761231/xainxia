package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

public class S_EnterGame extends ServerBasePacket {

    public S_EnterGame(long objId, String charName, int mapId, int x, int y) {
        super(ServerOpcodes.S_ENTER_GAME);
        put("objId", objId);
        put("charName", charName);
        put("mapId", mapId);
        put("x", x);
        put("y", y);
    }
}
