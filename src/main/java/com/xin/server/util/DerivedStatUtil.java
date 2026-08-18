package com.xin.server.util;

import com.xin.server.config.CharCreateConfig;
import com.xin.server.datatables.StatGrowthBonusTable;
import com.xin.server.types.BonusType;
import com.xin.server.types.StatType;

/**
 * 由四大素質推算單項戰鬥屬性的快捷工具（功能型計算工具）。
 * <p>
 * 適用於只需計算單一屬性的場景（如角色資訊顯示）；
 * 若需計算全部屬性，請改用 {@link CombatStatCalculator}。
 * 基底值來自 {@link CharCreateConfig}（{@code char_create.ini}）。
 */
public final class DerivedStatUtil {

    private DerivedStatUtil() {
    }

    /** 依體魄計算 HP 上限（基底 + 每點體魄加成）。 */
    public static int calcMaxHp(int constitution) {
        CharCreateConfig cfg = CharCreateConfig.get();
        return cfg.getBaseHp()
                + StatGrowthBonusTable.get().getBonus(StatType.CONSTITUTION, BonusType.MAX_HP) * constitution;
    }

    /** 依神識計算 MP 上限（基底 + 每點神識加成）。 */
    public static int calcMaxMp(int divineSense) {
        CharCreateConfig cfg = CharCreateConfig.get();
        return cfg.getBaseMp()
                + StatGrowthBonusTable.get().getBonus(StatType.DIVINE_SENSE, BonusType.MAX_MP) * divineSense;
    }

    /** 依體魄計算防禦值（基底 + 每點體魄加成）。 */
    public static int calcDefense(int constitution) {
        CharCreateConfig cfg = CharCreateConfig.get();
        return cfg.getBaseDefense()
                + StatGrowthBonusTable.get().getBonus(StatType.CONSTITUTION, BonusType.DEFENSE) * constitution;
    }
}
