package com.xin.server.types;

/**
 * 四維素質類型（對應 DB stat_growth_bonus.stat_type）。
 */
public final class StatType {

    /** 悟性（stats_intel）：法術領悟、仙藝熟練度 */
    public static final int COMPREHENSION = 1;
    /** 神識（stats_spirit）：MP、回魔、傀儡槽 */
    public static final int DIVINE_SENSE = 2;
    /** 敏捷（stats_agility）：命中、閃避 */
    public static final int AGILITY = 3;
    /** 體魄（stats_constitution）：HP、回血、防禦 */
    public static final int CONSTITUTION = 4;

    private StatType() {
    }
}
