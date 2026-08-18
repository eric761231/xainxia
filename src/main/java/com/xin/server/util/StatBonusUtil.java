package com.xin.server.util;

/**
 * 仙藝熟練度與法術領悟速率計算工具（功能型計算工具）。
 * <p>
 * 提供依悟性效率值（{@code craftProficiencyRate} / {@code spellLearnRate}）
 * 計算實際收益的靜態方法，供煉丹、修煉等系統呼叫。
 */
public final class StatBonusUtil {

    private StatBonusUtil() {
    }

    /**
     * 依悟性效率計算實際獲得的仙藝熟練度。
     *
     * @param baseGain             基礎熟練度增量
     * @param craftProficiencyRate 悟性帶來的熟練度效率（基礎 100 = 100%）
     * @return 實際增加的熟練度（最小 1）
     */
    public static int calcCraftProficiencyGain(int baseGain, int craftProficiencyRate) {
        return Math.max(1, baseGain * craftProficiencyRate / 100);
    }

    /**
     * 依悟性效率計算法術領悟所需時間。
     *
     * @param baseTime       基礎領悟時間（毫秒或遊戲刻數）
     * @param spellLearnRate 悟性帶來的學習效率（基礎 100 = 原速，120 = 快 20%）
     * @return 實際領悟時間（最小 1）
     */
    public static int calcSpellLearnTime(int baseTime, int spellLearnRate) {
        if (spellLearnRate <= 0) {
            return baseTime;
        }
        return Math.max(1, baseTime * 100 / spellLearnRate);
    }
}
