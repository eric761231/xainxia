package com.xin.server.packet.server;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 境界突破結果回應。
 */
public class S_BreakthroughResult extends ServerBasePacket {

    public static final String REASON_OK = "OK";
    public static final String REASON_NOT_IN_GAME = "NOT_IN_GAME";
    public static final String REASON_MAX_REALM = "MAX_REALM";
    public static final String REASON_LEVEL_NOT_READY = "LEVEL_NOT_READY";
    public static final String REASON_MISSING_ITEM = "MISSING_ITEM";
    public static final String REASON_FAILED = "FAILED";

    private S_BreakthroughResult(boolean success, String reason, String message) {
        super(ServerOpcodes.S_BREAKTHROUGH_RESULT);
        put("success", success);
        put("reason", reason);
        put("message", message);
    }

    public static S_BreakthroughResult ok(PcInstance pc) {
        S_BreakthroughResult packet = new S_BreakthroughResult(true, REASON_OK, "突破成功");
        packet.put("realm", pc.getRealmName());
        packet.put("realmStage", pc.getRealmStage());
        packet.put("realmLevel", pc.getRealmLevel());
        packet.put("hp", pc.getCurrentHp());
        packet.put("hpMax", pc.getMaxHp());
        packet.put("mp", pc.getCurrentMp());
        packet.put("mpMax", pc.getMaxMp());
        packet.put("defense", pc.getDefense());
        packet.put("attack", pc.getAttack());
        packet.put("hit", pc.getHit());
        packet.put("dodge", pc.getDodge());
        packet.put("hpRegen", pc.getHpRegen());
        packet.put("mpRegen", pc.getMpRegen());
        packet.put("puppetMax", pc.getPuppetMax());
        packet.put("spellLearnRate", pc.getSpellLearnRate());
        packet.put("craftProficiencyRate", pc.getCraftProficiencyRate());
        return packet;
    }

    public static S_BreakthroughResult fail(String reason, String message) {
        return new S_BreakthroughResult(false, reason, message);
    }
}
