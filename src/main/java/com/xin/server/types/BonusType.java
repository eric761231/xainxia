package com.xin.server.types;

/**
 * 素質成長加成類型（對應 DB stat_growth_bonus.bonus_type）。
 */
public final class BonusType {

    public static final String MAX_HP               = "max_hp";
    public static final String HP_REGEN             = "hp_regen";
    public static final String DEFENSE              = "defense";
    public static final String MAX_MP               = "max_mp";
    public static final String MP_REGEN             = "mp_regen";
    public static final String HIT                  = "hit";
    public static final String DODGE                = "dodge";
    public static final String PUPPET_SLOT          = "puppet_slot";
    public static final String SPELL_LEARN_RATE     = "spell_learn_rate";
    public static final String CRAFT_PROFICIENCY_RATE = "craft_proficiency_rate";

    private BonusType() {
    }
}
