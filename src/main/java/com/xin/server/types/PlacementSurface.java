package com.xin.server.types;

/**
 * 家具的放置面規則（對應 DB {@code property.placement}）。
 * <p>
 * 決定玩家可以把物件放在什麼樣的格子上：
 * <ul>
 *   <li>{@code floor} —— 必須是<b>可走格</b>。桌椅櫃子屬於此類，放下後該格變成不可走。</li>
 *   <li>{@code wall} —— 必須是<b>不可走格</b>。窗戶、掛畫貼在牆上，牆面正是角色走不進去的地方。</li>
 *   <li>{@code any} —— 不限制。</li>
 * </ul>
 */
public final class PlacementSurface {

    public static final String FLOOR = "floor";
    public static final String WALL  = "wall";
    public static final String ANY   = "any";

    private PlacementSurface() {
    }

    /**
     * 檢查某格是否符合該放置面規則。
     *
     * @param placement property.placement 的值
     * @param walkable  該格是否可通行
     */
    public static boolean accepts(String placement, boolean walkable) {
        if (placement == null) {
            return walkable;   // 預設當成 floor，最保守
        }
        switch (placement.trim().toLowerCase()) {
            case WALL: return !walkable;
            case ANY:  return true;
            case FLOOR:
            default:   return walkable;
        }
    }

    /** 規則的中文說明，供錯誤訊息使用。 */
    public static String describe(String placement) {
        if (placement == null) {
            return "地面";
        }
        switch (placement.trim().toLowerCase()) {
            case WALL: return "牆面";
            case ANY:  return "任意位置";
            default:   return "地面";
        }
    }
}
