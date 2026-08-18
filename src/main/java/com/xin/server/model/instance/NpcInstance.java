package com.xin.server.model.instance;

import com.xin.server.model.Character;

/**
 * 地圖 NPC 執行期實例（objId 由 IdFactoryNpc 分配）。
 * 數值由 {@link com.xin.server.datatables.NpcTable} 依 npc 模板套入。
 */
public class NpcInstance extends Character {

    private int npcTemplateId;

    public int getNpcTemplateId() {
        return npcTemplateId;
    }

    public void setNpcTemplateId(int npcTemplateId) {
        this.npcTemplateId = npcTemplateId;
    }

    /** 物件分類，見 {@link com.xin.server.types.NpcType} */
    private int _type;

    public int getType() {
        return _type;
    }

    public void setType(int type) {
        _type = type;
    }

    private int _gfxid;

    public int getGfxid() {
        return _gfxid;
    }

    public void setGfxid(int gfxid) {
        _gfxid = gfxid;
    }

    private int _defense;

    public int getDefense() {
        return _defense;
    }

    public void setDefense(int defense) {
        _defense = defense;
    }

    private int _baseDamage;

    public int getBaseDamage() {
        return _baseDamage;
    }

    public void setBaseDamage(int baseDamage) {
        _baseDamage = baseDamage;
    }

    private int _randDamage;

    public int getRandDamage() {
        return _randDamage;
    }

    public void setRandDamage(int randDamage) {
        _randDamage = randDamage;
    }
}
