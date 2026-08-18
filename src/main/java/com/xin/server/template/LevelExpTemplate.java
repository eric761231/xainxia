package com.xin.server.template;

import com.xin.server.datatables.LevelExpTable;

/**
 * 升級所需經驗值查詢門面（資料來自 DB {@code level_exp} 表）。
 * <p>
 * 每個境界內的小等級所需經驗值由 {@link LevelExpTable} 從 DB 載入，
 * 允許策劃設計非線性經驗曲線（如後期等級倍增）。
 * 若 DB 查無該等級，自動回退至線性公式 {@code level * 100}。
 */
public final class LevelExpTemplate {

    private LevelExpTemplate() {
    }

    /**
     * 取得境界內指定小等級升至下一重所需的經驗值上限。
     *
     * @param level 境界內小等級（1 起算）
     * @return 升級所需經驗值上限
     */
    public static int getExpMax(int level) {
        return LevelExpTable.get().getExpMax(level);
    }
}
