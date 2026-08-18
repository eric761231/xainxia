package com.xin.server.packet.server;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 角色完整屬性更新（突破、升級後同步前端）。
 */
public class S_CharStatsUpdate extends ServerBasePacket {

    private S_CharStatsUpdate() {
        super(ServerOpcodes.S_CHAR_STATS_UPDATE);
    }

    public static S_CharStatsUpdate of(PcInstance pc) {
        S_CharStatsUpdate packet = new S_CharStatsUpdate();
        packet.put("realm", pc.getRealmName());
        packet.put("realmStage", pc.getRealmStage());
        packet.put("realmLevel", pc.getRealmLevel());
        packet.put("exp", pc.getExp());
        packet.put("expMax", pc.getExpMax());
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
        packet.put("statsIntel", pc.getStatsIntel());
        packet.put("statsSpirit", pc.getStatsSpirit());
        packet.put("statsAgility", pc.getStatsAgility());
        packet.put("statsConstitution", pc.getStatsConstiution());
        return packet;
    }
}
