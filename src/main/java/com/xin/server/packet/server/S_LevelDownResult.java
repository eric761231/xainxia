package com.xin.server.packet.server;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 境界內降級結果。
 */
public class S_LevelDownResult extends ServerBasePacket {

    public static final String REASON_OK = "OK";

    private S_LevelDownResult(boolean success, String reason, String message) {
        super(ServerOpcodes.S_LEVEL_DOWN_RESULT);
        put("success", success);
        put("reason", reason);
        put("message", message);
    }

    public static S_LevelDownResult ok(PcInstance pc) {
        S_LevelDownResult packet = new S_LevelDownResult(true, REASON_OK, "降級");
        packet.put("realmLevel", pc.getRealmLevel());
        packet.put("exp", pc.getExp());
        packet.put("expMax", pc.getExpMax());
        return packet;
    }
}
