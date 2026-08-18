package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.template.PortalTemplate;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 地圖傳送點設置系統（對應 DB 表 {@code map_portal}）。
 * <p>
 * 每筆傳送點定義了地圖上的一個藍色光點位置（{@code loc_x}/{@code loc_y}）
 * 及其對應的目標地圖與座標。
 * 資料來源見 {@code sql/map_data.sql}。
 */
public class MapPortalTable {

    private static final Logger _log = LoggerFactory.getLogger(MapPortalTable.class);

    private static MapPortalTable _instance;

    /** key = portal_id */
    private static final HashMap<Integer, PortalTemplate>       _byPortalId = new HashMap<>();
    /** key = map_id，value = 該地圖下所有傳送點（唯讀 List） */
    private static final HashMap<Integer, List<PortalTemplate>>  _byMapId    = new HashMap<>();

    public static MapPortalTable get() {
        if (_instance == null) {
            _instance = new MapPortalTable();
        }
        return _instance;
    }

    /**
     * 重新從 DB 載入傳送點資料（用於 GM 熱更新）。
     */
    public static void reload() {
        _byPortalId.clear();
        _byMapId.clear();
        _instance = new MapPortalTable();
    }

    private MapPortalTable() {
        load();
    }

    private void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT portal_id, map_id, loc_x, loc_y, dest_map_id, dest_x, dest_y, "
                            + "trigger_range, dest_heading, name FROM map_portal");
            rs = ps.executeQuery();
            while (rs.next()) {
                PortalTemplate p = new PortalTemplate();
                p._portalId     = rs.getInt("portal_id");
                p._mapId        = rs.getInt("map_id");
                p._locX         = rs.getInt("loc_x");
                p._locY         = rs.getInt("loc_y");
                p._destMapId    = rs.getInt("dest_map_id");
                p._destX        = rs.getInt("dest_x");
                p._destY        = rs.getInt("dest_y");
                p._triggerRange = rs.getInt("trigger_range");
                p._destHeading  = rs.getInt("dest_heading");
                p._name         = rs.getString("name");
                _byPortalId.put(p._portalId, p);
                _byMapId.computeIfAbsent(p._mapId, k -> new ArrayList<>()).add(p);
            }
        } catch (SQLException e) {
            _log.error("載入地圖傳送點系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入地圖傳送點系統: " + _byPortalId.size() + "筆 (" + timer.get() + "ms)");
    }

    /**
     * 依 portal_id 取得傳送點；查無時回傳 {@code null}。
     */
    public PortalTemplate getPortal(int portalId) {
        return _byPortalId.get(portalId);
    }

    /**
     * 取得指定地圖的所有傳送點列表（供前端小地圖顯示藍色光點）。
     * 若該地圖無傳送點，回傳空 List。
     */
    public List<PortalTemplate> getPortalsByMap(int mapId) {
        List<PortalTemplate> list = _byMapId.get(mapId);
        return list != null ? list : Collections.emptyList();
    }
}
