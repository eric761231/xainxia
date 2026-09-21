package com.xin.server.types;

/**
 * 地圖的場景物件佈局模式（對應 DB {@code map.layout_mode} 的英文代號字串）。
 * <p>
 * DB 存易讀的英文代號，載入時由 {@link #of(String)} 轉成 int 常數，
 * 決定 {@link com.xin.server.datatables.SceneSpawnTable#spawnAll()} 如何放置場景物件。
 *
 * <table border="1">
 *   <tr><th>代號</th><th>常數</th><th>說明</th></tr>
 *   <tr><td>static</td><td>{@link #STATIC}</td>
 *       <td>依 {@code spawnlist_scene} 的 locx/locy 精確放置（商人圖、劇情圖）</td></tr>
 *   <tr><td>random</td><td>{@link #RANDOM}</td>
 *       <td>每次啟動重新隨機分佈（刷怪圖，每局長得不一樣）</td></tr>
 *   <tr><td>player</td><td>{@link #PLAYER}</td>
 *       <td>由玩家自行佈置（靈田／礦脈）；第二階段實作，目前視同 static</td></tr>
 * </table>
 */
public final class MapLayoutMode {

    /** 固定編寫：依 spawnlist_scene 座標精確放置 */
    public static final int STATIC = 0;
    /** 每局重新隨機：由 PropertyScatter 分佈 */
    public static final int RANDOM = 1;
    /** 玩家佈置：靈田／礦脈（尚未實作，暫視同 STATIC） */
    public static final int PLAYER = 2;

    private MapLayoutMode() {
    }

    /** 把 DB 的英文代號字串轉成常數；未知或 {@code null} 一律視為 {@link #STATIC}。 */
    public static int of(String modeName) {
        if (modeName == null) {
            return STATIC;
        }
        switch (modeName.trim().toLowerCase()) {
            case "random": return RANDOM;
            case "player": return PLAYER;
            case "static": return STATIC;
            default:       return STATIC;
        }
    }
}
