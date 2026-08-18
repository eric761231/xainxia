package com.xin.server.packet.server;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 境界內升級結果。
 */
public class S_LevelUpResult extends ServerBasePacket {

    public static final String REASON_OK = "OK";
    public static final String REASON_NOT_IN_GAME = "NOT_IN_GAME";
    public static final String REASON_INVALID_AMOUNT = "INVALID_AMOUNT";
    public static final String REASON_MAX_LEVEL = "MAX_LEVEL";

    private S_LevelUpResult(boolean success, String reason, String message) {
        super(ServerOpcodes.S_LEVEL_UP_RESULT);
        put("success", success);
        put("reason", reason);
        put("message", message);
    }

    public static S_LevelUpResult ok(PcInstance pc) {
        S_LevelUpResult packet = new S_LevelUpResult(true, REASON_OK, "升級成功");
        packet.put("realmLevel", pc.getRealmLevel());
        packet.put("exp", pc.getExp());
        packet.put("expMax", pc.getExpMax());
        return packet;
    }

    public static S_LevelUpResult fail(String reason, String message) {
        return new S_LevelUpResult(false, reason, message);
    }
}
