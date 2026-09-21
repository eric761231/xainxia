package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.world.MapGrid;
import com.xin.util.DatabaseFactory;
import com.xin.util.SQLUtil;

/**
 * 地圖的逐格地形碰撞（對應 DB 表 {@code map_collision}）。
 * <p>
 * 在此之前伺服器只有 {@code min_x/max_x} 邊界與場景物件佔格，
 * 無法表達牆、水、懸崖這類「地形本身走不過去」的格子。
 * <p>
 * 與 {@link CharacterDecorationTable} 同樣<b>不做全表快取</b> ——
 * 真正的快取是 {@link MapGrid} 的地形陣列，本表只負責持久化：
 * 建 grid 時載入一次，GM 編輯時即時寫回。
 * 資料來源見 {@code sql/schema_all.sql}。
 */
public class MapCollisionTable {

    private static final Logger _log = LoggerFactory.getLogger(MapCollisionTable.class);

    private static MapCollisionTable _instance;

    public static MapCollisionTable get() {
        if (_instance == null) {
            _instance = new MapCollisionTable();
        }
        return _instance;
    }

    private MapCollisionTable() {
    }

    /** 把某地圖的地形碰撞灌進剛建立的 grid。 */
    public void loadInto(MapGrid grid) {
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        int count = 0;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT loc_x, loc_y FROM map_collision WHERE map_id = ?");
            ps.setInt(1, grid.getMapId());
            rs = ps.executeQuery();
            while (rs.next()) {
                grid.setTerrainBlocked(rs.getInt("loc_x"), rs.getInt("loc_y"), true);
                count++;
            }
            _log.info("載入地形碰撞: 地圖{} 共{}格", grid.getMapId(), count);
        } catch (SQLException e) {
            _log.error("載入地形碰撞失敗 map=" + grid.getMapId(), e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /**
     * 標記一格為不可通行。
     * <p>
     * 用 {@code INSERT IGNORE} —— 複合主鍵讓重複標記同一格自然無害，
     * 呼叫端不必先查有沒有。
     */
    public boolean insert(int mapId, int x, int y) {
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "INSERT IGNORE INTO map_collision (map_id, loc_x, loc_y) VALUES (?, ?, ?)");
            ps.setInt(1, mapId);
            ps.setInt(2, x);
            ps.setInt(3, y);
            ps.executeUpdate();
            return true;
        } catch (SQLException e) {
            _log.error("寫入地形碰撞失敗 map=" + mapId + " (" + x + "," + y + ")", e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /** 取消一格的地形碰撞。 */
    public boolean delete(int mapId, int x, int y) {
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "DELETE FROM map_collision WHERE map_id = ? AND loc_x = ? AND loc_y = ?");
            ps.setInt(1, mapId);
            ps.setInt(2, x);
            ps.setInt(3, y);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            _log.error("刪除地形碰撞失敗 map=" + mapId + " (" + x + "," + y + ")", e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }
}
