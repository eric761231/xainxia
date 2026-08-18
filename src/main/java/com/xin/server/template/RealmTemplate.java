package com.xin.server.template;

import com.xin.server.datatables.RealmTable;

/**
 * 修煉境界階段常數與查詢門面。
 * <p>
 * 境界 ID 常數（{@link #BODY_TEMPERING} 等）為程式邏輯用途，保留在 Java 中。
 * 境界名稱與各境界小等級上限則由 {@link RealmTable} 從 DB 載入，
 * 方便策劃調整境界設計而無需重新編譯。
 */
public final class RealmTemplate {

    // ── 境界 ID 常數（程式邏輯用，不移至 DB）────────────────────────────────
    public static final int BODY_TEMPERING       = 0; // 鍛體期
    public static final int QI_REFINING          = 1; // 練氣期
    public static final int FOUNDATION           = 2; // 築基期
    public static final int GOLDEN_CORE          = 3; // 金丹期
    public static final int NASCENT_SOUL         = 4; // 元嬰期
    public static final int SPIRIT_TRANSFORMATION = 5; // 化神期
    public static final int UNITY                = 6; // 合體期
    public static final int MAHAYANA             = 7; // 大乘期
    public static final int TRIBULATION          = 8; // 渡劫期
    public static final int ASCENSION            = 9; // 飛昇期

    public static final int MIN           = BODY_TEMPERING;
    public static final int MAX           = ASCENSION;
    public static final int DEFAULT_STAGE = BODY_TEMPERING;

    private RealmTemplate() {
    }

    /** 境界 ID 是否在有效範圍內。 */
    public static boolean isValid(int stage) {
        return stage >= MIN && stage <= MAX;
    }

    /**
     * 取得指定境界的顯示名稱（從 DB {@code realm_definition} 表查詢）。
     * 若 DB 查無此境界則回傳 {@code "?"}。
     */
    public static String getName(int stage) {
        return RealmTable.get().getName(stage);
    }

    /**
     * 取得指定境界的小等級上限（從 DB {@code realm_definition} 表查詢）。
     * 達到此上限才可嘗試突破至下一境界。
     * 若 DB 查無此境界則 fallback 回傳 10。
     */
    public static int getLevelsPerRealm(int stage) {
        return RealmTable.get().getLevelsPerRealm(stage);
    }

    /** 飛昇期為終點境界，無法再突破。*/
    public static boolean hasNextStage(int stage) {
        return stage >= MIN && stage < MAX;
    }
    
    // 境界重級
    public int _realStage;
    
    // 境界名稱
    public String _realName;
    
    //
    
    
    
}
