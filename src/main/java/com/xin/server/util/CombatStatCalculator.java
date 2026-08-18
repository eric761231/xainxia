package com.xin.server.util;

import com.xin.server.config.CharCreateConfig;
import com.xin.server.datatables.RealmTable;
import com.xin.server.datatables.StatGrowthBonusTable;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.types.BonusType;
import com.xin.server.types.StatType;

/**
 * 角色戰鬥屬性計算器（功能型計算工具）。
 * <p>
 * 依以下三層疊加計算最終屬性，確保所有修改只在此處進行：
 * <ol>
 *   <li>創角基礎值（{@link CharCreateConfig}）</li>
 *   <li>四維素質成長加成（{@link StatGrowthBonusTable}）</li>
 *   <li>境界突破累計獎勵 + 重級累計獎勵（{@link RealmTable}）</li>
 * </ol>
 */
public final class CombatStatCalculator {

    /**
     * 計算結果容器。
     * 欄位直接公開（L1J 慣例），由 {@link #calculate} 填入後傳回，再由 {@link #apply} 套用至角色。
     */
    public static final class Result {
        public int _maxHp;                // HP 上限
        public int _maxMp;                // MP 上限
        public int _defense;              // 防禦值
        public int _attack;               // 攻擊值
        public int _hit;                  // 命中值
        public int _dodge;                // 閃避值
        public int _hpRegen;              // 每回合 HP 回復
        public int _mpRegen;              // 每回合 MP 回復
        public int _puppetMax;            // 寵物/傀儡上限（最多 4 隻）
        public int _spellLearnRate;       // 法術學習效率（基礎 100）
        public int _craftProficiencyRate; // 仙藝熟練度成長倍率（基礎 100）

        public Result() {
        }
    }

    private CombatStatCalculator() {
    }

    /**
     * 依角色當前四維素質與境界計算完整戰鬥屬性。
     *
     * @param pc 要計算的角色實例
     * @return 計算結果（不直接套用，需呼叫 {@link #apply}）
     */
    public static Result calculate(PcInstance pc) {
        CharCreateConfig cfg       = CharCreateConfig.get();
        StatGrowthBonusTable statT = StatGrowthBonusTable.get();

        // ── 步驟 1：讀取四維素質 ──────────────────────────────────────────────
        int comprehension = pc.getStatsIntel();       // 悟性：影響法術學習、仙藝熟練
        int divineSense   = pc.getStatsSpirit();      // 神識：影響 MP 上限、回魔、傀儡數
        int agility       = pc.getStatsAgility();     // 敏捷：影響命中、閃避
        int constitution  = pc.getStatsConstiution(); // 體魄：影響 HP 上限、回血、防禦

        // ── 步驟 2：基礎值 + 素質成長加成 ────────────────────────────────────
        Result r = new Result();
        r._maxHp   = cfg.getBaseHp()
                + statT.getBonus(StatType.CONSTITUTION, BonusType.MAX_HP) * constitution;
        r._maxMp   = cfg.getBaseMp()
                + statT.getBonus(StatType.DIVINE_SENSE, BonusType.MAX_MP) * divineSense;
        r._defense = cfg.getBaseDefense()
                + statT.getBonus(StatType.CONSTITUTION, BonusType.DEFENSE) * constitution;
        r._attack  = cfg.getBaseAttack();
        r._hit     = cfg.getBaseHit()
                + statT.getBonus(StatType.AGILITY, BonusType.HIT) * agility;
        r._dodge   = cfg.getBaseDodge()
                + statT.getBonus(StatType.AGILITY, BonusType.DODGE) * agility;
        r._hpRegen = cfg.getBaseHpRegen()
                + statT.getBonus(StatType.CONSTITUTION, BonusType.HP_REGEN) * constitution;
        r._mpRegen = cfg.getBaseMpRegen()
                + statT.getBonus(StatType.DIVINE_SENSE, BonusType.MP_REGEN) * divineSense;
        r._puppetMax = Math.min(cfg.getMaxPuppet(),
                cfg.getBasePuppetSlot()
                        + statT.getBonus(StatType.DIVINE_SENSE, BonusType.PUPPET_SLOT) * divineSense);
        r._spellLearnRate = cfg.getBaseSpellLearnRate()
                + statT.getBonus(StatType.COMPREHENSION, BonusType.SPELL_LEARN_RATE) * comprehension;
        r._craftProficiencyRate = cfg.getBaseCraftProficiencyRate()
                + statT.getBonus(StatType.COMPREHENSION, BonusType.CRAFT_PROFICIENCY_RATE) * comprehension;

        // ── 步驟 3：疊加境界突破累計獎勵 ──────────────────────────────────────
        RealmTable.StageBonus stageBonus =
                RealmTable.get().sumStageBonus(pc.getRealmStage());
        r._maxHp   += stageBonus._maxHp;
        r._maxMp   += stageBonus._maxMp;
        r._defense += stageBonus._defense;
        r._attack  += stageBonus._attack;

        // ── 步驟 4：疊加同境界重級累計獎勵 ───────────────────────────────────
        RealmTable.LevelBonus levelBonus =
                RealmTable.get().sumLevelBonus(pc.getRealmStage(), pc.getRealmLevel());
        r._maxHp   += levelBonus._maxHp;
        r._maxMp   += levelBonus._maxMp;
        r._defense += levelBonus._defense;
        r._attack  += levelBonus._attack;

        return r;
    }

    /**
     * 將 {@link #calculate} 的結果套用至角色。
     *
     * @param pc        目標角色
     * @param fillToMax {@code true} 表示填滿 HP/MP（創角或突破境界時使用）；
     *                  {@code false} 表示依差值等比例保留（升級時使用）
     */
    public static void apply(PcInstance pc, boolean fillToMax) {
        Result r = calculate(pc);
        if (fillToMax) {
            // 創角 / 突破：HP、MP 直接填滿
            pc.setMaxHp(r._maxHp);
            pc.setCurrentHp(r._maxHp);
            pc.setMaxMp(r._maxMp);
            pc.setCurrentMp(r._maxMp);
        } else {
            // 升級：依上限增減量調整當前值，不超過新上限
            int oldMaxHp = pc.getMaxHp();
            int oldMaxMp = pc.getMaxMp();
            pc.setMaxHp(r._maxHp);
            pc.setMaxMp(r._maxMp);
            if (oldMaxHp > 0) {
                pc.setCurrentHp(Math.min(pc.getCurrentHp() + (r._maxHp - oldMaxHp), r._maxHp));
            } else {
                pc.setCurrentHp(r._maxHp);
            }
            if (oldMaxMp > 0) {
                pc.setCurrentMp(Math.min(pc.getCurrentMp() + (r._maxMp - oldMaxMp), r._maxMp));
            } else {
                pc.setCurrentMp(r._maxMp);
            }
        }
        pc.setDefense(r._defense);
        pc.setAttack(r._attack);
        pc.setHit(r._hit);
        pc.setDodge(r._dodge);
        pc.setHpRegen(r._hpRegen);
        pc.setMpRegen(r._mpRegen);
        pc.setPuppetMax(r._puppetMax);
        pc.setSpellLearnRate(r._spellLearnRate);
        pc.setCraftProficiencyRate(r._craftProficiencyRate);
    }
}
