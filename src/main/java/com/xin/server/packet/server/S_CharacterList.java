package com.xin.server.packet.server;

import java.util.List;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

public class S_CharacterList extends ServerBasePacket {

    public S_CharacterList() {
        super(ServerOpcodes.S_CHARACTER_LIST);
    }

    public static S_CharacterList of(List<PcInstance> characters) {
        S_CharacterList packet = new S_CharacterList();
        ArrayNode array = packet.newArray();
        for (PcInstance character : characters) {
            ObjectNode node = packet.newObject();
            node.put("objId", character.getId());
            node.put("name", character.getName());
            node.put("level", character.getRealmLevel());
            node.put("sex", character.getSex());
            node.put("attribute", character.getAttribute());
            node.put("realm", character.getRealmName());
            node.put("exp", character.getExp());
            node.put("expMax", character.getExpMax());
            node.put("hp", character.getCurrentHp());
            node.put("hpMax", character.getMaxHp());
            node.put("mp", character.getCurrentMp());
            node.put("mpMax", character.getMaxMp());
            node.put("defense", character.getDefense());
            node.put("attack", character.getAttack());
            node.put("hit", character.getHit());
            node.put("dodge", character.getDodge());
            node.put("puppetMax", character.getPuppetMax());
            node.put("spellLearnRate", character.getSpellLearnRate());
            node.put("craftProficiencyRate", character.getCraftProficiencyRate());
            node.put("statsIntel", character.getStatsIntel());
            node.put("statsSpirit", character.getStatsSpirit());
            node.put("statsAgility", character.getStatsAgility());
            node.put("statsConstitution", character.getStatsConstiution());
            node.put("natalWeapon", character.getNatalWeaponName());
            node.put("coreTechnique", character.getCoreTechnique());
            node.put("faction", character.getFaction());
            node.put("lifeJob", character.getLifeJob());
            node.put("lifeJobLevel", character.getLifeJobLevel());
            array.add(node);
        }
        packet.putArray("characters", array);
        return packet;
    }
}
