package com.xin.server.util;

import com.xin.server.datatables.LevelExpTable;

/**
 * 經驗值計算工具（參照天堂 L1J ExpTable 設計）。
 * <p>
 * XinServer 採境界內小等級制，與 L1J 全域累積經驗不同：
 * 每次突破境界後經驗歸零，重新從第 1 重開始累積。
 * 本工具提供等級所需經驗、進度百分比、實際獲得量等計算。
 */
public final class ExpCalculator {

    private ExpCalculator() {
    }

    /**
     * 取得指定境界內小等級升至下一重所需的經驗值上限。
     * 委派 {@link LevelExpTable}，DB 無資料時 fallback 為 {@code level * 100}。
     *
     * @param realmLevel 境界內小等級（1 起算）
     * @return 升級所需經驗上限
     */
    public static int getExpMax(int realmLevel) {
        return LevelExpTable.get().getExpMax(realmLevel);
    }

    /**
     * 計算當前等級的經驗進度百分比（0～100）。
     * 供前端進度條使用（對應 L1J 的 {@code getExpPercentage}）。
     *
     * @param exp    當前累積經驗值
     * @param expMax 升級所需經驗上限
     * @return 百分比（0～100），expMax <= 0 時回傳 0
     */
    public static int getExpPercentage(int exp, int expMax) {
        if (expMax <= 0) {
            return 0;
        }
        int pct = exp * 100 / expMax;
        return Math.min(pct, 100);
    }

    /**
     * 依倍率計算實際獲得的經驗值（最小保證為 1）。
     * 供未來怪物掉落 exp 加成、修煉加速等系統呼叫。
     *
     * @param baseExp 基礎經驗值（怪物或事件給予的原始值）
     * @param expRate 經驗倍率（基礎 100 = 100%，200 = 雙倍）
     * @return 實際獲得的經驗值
     */
    public static int calcGain(int baseExp, int expRate) {
        if (baseExp <= 0) {
            return 0;
        }
        return Math.max(1, baseExp * expRate / 100);
    }
}
