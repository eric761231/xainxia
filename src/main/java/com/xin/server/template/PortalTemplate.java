package com.xin.server.template;

/**
 * 傳送點記憶體存放區（對應 DB 表 {@code map_portal}）。
 * 欄位直接公開（L1J 慣例），由 {@link com.xin.server.datatables.MapPortalTable} 填入後唯讀使用。
 * <p>
 * 前端在小地圖上以藍色光點呈現 {@code _locX} / {@code _locY} 的位置。
 * 玩家走近到 {@code _triggerRange} 格以內（Chebyshev 距離）即可使用傳送點。
 */
public class PortalTemplate {

    public int    _portalId;      // 傳送點編號
    public int    _mapId;         // 所在地圖編號
    public int    _locX;          // 傳送點 X 座標（藍色光點位置）
    public int    _locY;          // 傳送點 Y 座標
    public int    _destMapId;     // 目標地圖編號
    public int    _destX;         // 目標 X 座標
    public int    _destY;         // 目標 Y 座標
    public int    _triggerRange;  // 觸發範圍（格數，Chebyshev 距離）
    public int    _destHeading;   // 到達面向 0..7；-1=保留玩家當下面向
    public String _name;          // 傳送點顯示名稱（如：前往青雲山）

    public PortalTemplate() {
    }

    /**
     * 判斷角色是否在此傳送點的觸發範圍內（Chebyshev 距離）。
     *
     * @param x 角色當前 X 座標
     * @param y 角色當前 Y 座標
     * @return {@code true} 表示可使用此傳送點
     */
    public boolean isInRange(int x, int y) {
        return Math.max(Math.abs(x - _locX), Math.abs(y - _locY)) <= _triggerRange;
    }
}
