package com.xin.server.template;

/**
 * 地圖設定記憶體存放區（對應 DB 表 {@code map}）。
 * 欄位直接公開（L1J 慣例），由 {@link com.xin.server.datatables.MapTable} 填入後唯讀使用。
 */
public class MapTemplate {

    public int     _mapId;       // 地圖編號
    public String  _name;        // 地圖顯示名稱
    public int     _minX;        // X 座標最小值（邊界）
    public int     _maxX;        // X 座標最大值（邊界）
    public int     _minY;        // Y 座標最小值（邊界）
    public int     _maxY;        // Y 座標最大值（邊界）
    public boolean _safeZone;    // 安全區（true = 禁止攻擊）
    public boolean _pkEnabled;   // 允許 PK

    public MapTemplate() {
    }

    /** 判斷座標是否在地圖合法範圍內。 */
    public boolean isValidCoord(int x, int y) {
        return x >= _minX && x <= _maxX && y >= _minY && y <= _maxY;
    }
}
