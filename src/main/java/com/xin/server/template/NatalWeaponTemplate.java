package com.xin.server.template;

/**
 * 本命攻擊法寶武器類型。
 */
public final class NatalWeaponTemplate {

    public static final int SWORD = 0;
    public static final int BLADE = 1;
    public static final int SPEAR = 2;
    public static final int WHIP = 3;
    public static final int FAN = 4;
    public static final int FIST = 5;

    public static final int MIN = SWORD;
    public static final int MAX = FIST;

    public static final String[] NAMES = {
            "劍", "刀", "槍", "鞭", "扇", "拳"
    };

    public static final String[] DESCRIPTIONS = {
            "劍形本命法寶，鋒芒畢露",
            "刀形本命法寶，破甲裂空",
            "槍形本命法寶，一刺千里",
            "鞭形本命法寶，靈動纏擊",
            "扇形本命法寶，御風成刃",
            "拳套本命法寶，近身爆發"
    };

    private NatalWeaponTemplate() {
    }

    public static boolean isValid(int natalWeaponId) {
        return natalWeaponId >= MIN && natalWeaponId <= MAX;
    }

    public static String getName(int natalWeaponId) {
        if (!isValid(natalWeaponId)) {
            return "?";
        }
        return NAMES[natalWeaponId];
    }
}
