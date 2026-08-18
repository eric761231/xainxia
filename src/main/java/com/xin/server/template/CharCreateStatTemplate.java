package com.xin.server.template;

import com.xin.server.config.CharCreateConfig;

/**
 * 創角四維配點規則查詢門面（數值來自 {@link CharCreateConfig} / {@code char_create.ini}）。
 * <p>
 * 各基底值與自由點數不再寫死在 Java，而是透過 INI 設定檔管理，
 * 方便策劃在無需重新編譯的情況下調整創角門檻。
 */
public final class CharCreateStatTemplate {

    private CharCreateStatTemplate() {
    }

    /** 四維素質各別的初始基底值（創角時每項最低值）。 */
    public static int getBaseStatPerAttr() {
        return CharCreateConfig.get().getBaseStatPerAttr();
    }

    /** 創角自由分配點數總量。 */
    public static int getBonusPool() {
        return CharCreateConfig.get().getBonusPool();
    }

    /** 新角色的預設出生地圖 ID。 */
    public static int getDefaultMapId() {
        return CharCreateConfig.get().getDefaultMapId();
    }

    /** 新角色的預設出生 X 座標。 */
    public static int getDefaultX() {
        return CharCreateConfig.get().getDefaultX();
    }

    /** 新角色的預設出生 Y 座標。 */
    public static int getDefaultY() {
        return CharCreateConfig.get().getDefaultY();
    }

    /**
     * 驗證玩家輸入的四維配點是否合法：
     * 每項不得低於基底值，各項之和恰好等於「基底 * 4 + 自由點數」。
     */
    public static boolean validate(int intel, int spirit, int agility, int constitution) {
        int base = getBaseStatPerAttr();
        int pool = getBonusPool();

        if (intel < base || intel > base + pool) return false;
        if (spirit < base || spirit > base + pool) return false;
        if (agility < base || agility > base + pool) return false;
        if (constitution < base || constitution > base + pool) return false;

        int spent = (intel - base) + (spirit - base) + (agility - base) + (constitution - base);
        return spent == pool;
    }
}
