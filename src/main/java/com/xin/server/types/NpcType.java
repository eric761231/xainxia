package com.xin.server.types;

/**
 * NPC／地圖物件分類（對應 DB {@code npc.type_name} 的英文代號字串）。
 * <p>
 * DB 存易讀的英文代號，載入時由 {@link #of(String)} 轉成 int 常數，
 * 封包一律傳 int（見 {@code S_NPC_PACK} 的 {@code type} 欄位）。
 *
 * <table border="1">
 *   <tr><th>代號</th><th>常數</th><th>說明</th></tr>
 *   <tr><td>monster</td><td>{@link #MONSTER}</td><td>可攻擊的怪物</td></tr>
 *   <tr><td>npc</td>    <td>{@link #NPC}</td>    <td>可交談的 NPC</td></tr>
 *   <tr><td>shop</td>   <td>{@link #SHOP}</td>   <td>可交談並買賣的商店 NPC</td></tr>
 *   <tr><td>gather</td> <td>{@link #GATHER}</td> <td>可互動採集的資源（植物／礦物）</td></tr>
 *   <tr><td>scenery</td><td>{@link #SCENERY}</td><td>純裝飾場景物件，不可互動</td></tr>
 * </table>
 */
public final class NpcType {

    /** 可攻擊的怪物 */
    public static final int MONSTER = 0;
    /** 可交談的 NPC */
    public static final int NPC     = 1;
    /** 可交談並買賣的商店 NPC */
    public static final int SHOP    = 2;
    /** 可互動採集的資源物件（植物／礦物） */
    public static final int GATHER  = 3;
    /** 純裝飾場景物件，不可互動 */
    public static final int SCENERY = 4;

    private NpcType() {
    }

    /**
     * 把 DB 的英文代號字串轉成常數；未知或 {@code null} 一律視為 {@link #SCENERY}
     * （最保守：不可互動，避免誤開放攻擊或對話）。
     */
    public static int of(String typeName) {
        if (typeName == null) {
            return SCENERY;
        }
        switch (typeName.trim().toLowerCase()) {
            case "monster": return MONSTER;
            case "npc":     return NPC;
            case "shop":    return SHOP;
            case "gather":  return GATHER;
            case "scenery": return SCENERY;
            default:        return SCENERY;
        }
    }

    /** 是否可被攻擊。 */
    public static boolean isAttackable(int type) {
        return type == MONSTER;
    }

    /** 是否可交談（一般 NPC 與商店）。 */
    public static boolean isTalkable(int type) {
        return type == NPC || type == SHOP;
    }

    /** 是否可買賣。 */
    public static boolean isShop(int type) {
        return type == SHOP;
    }

    /** 是否可採集。 */
    public static boolean isGatherable(int type) {
        return type == GATHER;
    }

    /** 是否可做任何互動（交談／買賣／採集／攻擊皆算）。 */
    public static boolean isInteractive(int type) {
        return type != SCENERY;
    }
}
