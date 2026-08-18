package com.xin.server.template;
/**
 * 八大天賦靈根 attribute（0~7）。
 */
public final class AttributeTemplate {

    public static final int METAL = 0;
    public static final int WOOD = 1;
    public static final int WATER = 2;
    public static final int FIRE = 3;
    public static final int EARTH = 4;
    public static final int WIND = 5;
    public static final int THUNDER = 6;
    public static final int ILLUSION = 7;

    public static final int MIN = METAL;
    public static final int MAX = ILLUSION;

    public static final String[] NAMES = {
            "金", "木", "水", "火", "土", "風", "雷", "幻"
    };

    private AttributeTemplate() {
    }

    public static boolean isValid(int attribute) {
        return attribute >= MIN && attribute <= MAX;
    }

    public static String getName(int attribute) {
        if (!isValid(attribute)) {
            return "?";
        }
        return NAMES[attribute];
    }
}
