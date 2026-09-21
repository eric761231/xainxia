package com.xin.server.template;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 一張地圖的圖磚資料（對應 {@code resources/maps/<mapId>.json}）。
 * <p>
 * 欄位直接公開（L1J 慣例），由 {@link com.xin.server.datatables.MapTileTable}
 * 填入後唯讀使用。
 */
public class MapTileTemplate {

    /** 一格的鋪法：座標 + 圖磚編號。 */
    public static class Cell {
        public final int _x;
        public final int _y;
        public final int _tileId;

        public Cell(int x, int y, int tileId) {
            _x = x;
            _y = y;
            _tileId = tileId;
        }
    }

    public int _mapId;
    public int _tileWidth;
    public int _tileHeight;

    /** 可走區的格座標範圍。 */
    public int _walkMin;
    public int _walkMax;

    /** 圖磚檔所在的子資料夾（相對前端的 {@code assets/tiles/}）。 */
    public String _tileDir = "";

    /** 圖磚編號 → 檔名。用 LinkedHashMap 保留檔案裡的順序，除錯時好讀。 */
    public final Map<Integer, String> _tiles = new LinkedHashMap<>();

    /** 逐格的鋪法。沒列到的座標就是不鋪。 */
    public final List<Cell> _ground = new ArrayList<>();

    /** 該編號有沒有對應的圖磚檔。 */
    public boolean isKnownTile(int tileId) {
        return _tiles.containsKey(tileId);
    }
}
