package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.template.MapTemplate;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 地圖設定系統（對應 DB 表 {@code map}）。
 * <p>
 * 保存每張地圖的名稱、可移動邊界與屬性，供移動/傳送邊界驗證與小地圖地名顯示使用。
 * 資料來源見 {@code sql/map_data.sql}。
 *
 * @author user
 */
public class MapTable {

    private static final Logger _log = LoggerFactory.getLogger(MapTable.class);

    private static MapTable _instance;

    /** key = map_id */
    private final HashMap<Integer, MapTemplate> _mapData = new HashMap<>();

    public static MapTable get() {
        if (_instance == null) {
            _instance = new MapTable();
        }
        return _instance;
    }

    /** 重新從 DB 載入地圖設定（GM 熱更新用）。 */
    public static void reload() {
        _instance = new MapTable();
    }

    private MapTable() {
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
                    "SELECT map_id, name, min_x, max_x, min_y, max_y, safe_zone, pk_enabled FROM map");
            rs = ps.executeQuery();
            while (rs.next()) {
                MapTemplate m = new MapTemplate();
                m._mapId     = rs.getInt("map_id");
                m._name      = rs.getString("name");
                m._minX      = rs.getInt("min_x");
                m._maxX      = rs.getInt("max_x");
                m._minY      = rs.getInt("min_y");
                m._maxY      = rs.getInt("max_y");
                m._safeZone  = rs.getBoolean("safe_zone");
                m._pkEnabled = rs.getBoolean("pk_enabled");
                _mapData.put(m._mapId, m);
            }
        } catch (SQLException e) {
            _log.error("載入地圖設定系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入地圖設定系統: " + _mapData.size() + "筆 (" + timer.get() + "ms)");
    }

    /** 取得地圖設定；查無時回傳 {@code null}。 */
    public MapTemplate getMap(int mapId) {
        return _mapData.get(mapId);
    }

    /** 取得地圖顯示名稱；查無時回傳空字串。 */
    public String getName(int mapId) {
        MapTemplate m = _mapData.get(mapId);
        return m != null ? m._name : "";
    }

    /** 座標是否在該地圖合法範圍內；地圖不存在時回傳 {@code false}。 */
    public boolean isValidCoord(int mapId, int x, int y) {
        MapTemplate m = _mapData.get(mapId);
        return m != null && m.isValidCoord(x, y);
    }
}
