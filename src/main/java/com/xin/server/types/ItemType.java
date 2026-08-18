package com.xin.server.types;

/**
 * 道具類型（對應 DB item.item_type）。
 */
public final class ItemType {

    public static final int ETC    = 0; // 一般道具
    public static final int WEAPON = 1; // 武器
    public static final int ARMOR  = 2; // 防具

    private ItemType() {
    }
}
