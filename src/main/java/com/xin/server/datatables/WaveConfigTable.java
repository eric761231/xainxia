package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.template.WaveConfigTemplate;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 波次設定（{@code wave_config} + {@code wave_npc}）。
 * <p>
 * 這些數字以前寫死在 {@code WaveManager} 裡。搬進資料表的理由不是「設定檔比較好」，
 * 而是<b>調難度不該重新編譯</b> —— 第一波幾隻、隔幾秒、哪一波開始出妖魔，
 * 這些是企劃在調的東西，改一行 SQL 就該生效。
 */
public class WaveConfigTable {

    private static final Logger _log = LoggerFactory.getLogger(WaveConfigTable.class);

    private static WaveConfigTable _instance;

    private final Map<Integer, WaveConfigTemplate> _configs = new HashMap<>();

    public static WaveConfigTable get() {
        if (_instance == null) {
            _instance = new WaveConfigTable();
        }
        return _instance;
    }

    public static void reload() {
        _instance = new WaveConfigTable();
    }

    private WaveConfigTable() {
        load();
    }

    private void load() {
        PerformanceTimer timer = new PerformanceTimer();
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DatabaseFactory.getInstance().getConnection();
            ps = con.prepareStatement(
                    "SELECT map_id, enabled, base_count, per_wave, max_count, "
                    + "break_seconds, spawn_min_dist, spawn_max_dist, hp_per_wave, note "
                    + "FROM wave_config");
            rs = ps.executeQuery();
            while (rs.next()) {
                WaveConfigTemplate t = new WaveConfigTemplate();
                t._mapId        = rs.getInt("map_id");
                t._enabled      = rs.getBoolean("enabled");
                t._baseCount    = rs.getInt("base_count");
                t._perWave      = rs.getInt("per_wave");
                t._maxCount     = rs.getInt("max_count");
                t._breakSeconds = rs.getInt("break_seconds");
                t._spawnMinDist = rs.getInt("spawn_min_dist");
                t._spawnMaxDist = rs.getInt("spawn_max_dist");
                t._hpPerWave    = rs.getInt("hp_per_wave");
                t._note         = rs.getString("note");
                _configs.put(t._mapId, t);
            }
            SQLUtil.close(rs);
            SQLUtil.close(ps);

            ps = con.prepareStatement(
                    "SELECT map_id, npc_id, weight, min_wave FROM wave_npc ORDER BY min_wave, id");
            rs = ps.executeQuery();
            int entries = 0;
            while (rs.next()) {
                WaveConfigTemplate t = _configs.get(rs.getInt("map_id"));
                if (t == null) {
                    _log.warn("wave_npc 指向沒有設定的地圖: {}", rs.getInt("map_id"));
                    continue;
                }
                t._npcs.add(new WaveConfigTemplate.Entry(
                        rs.getInt("npc_id"), rs.getInt("weight"), rs.getInt("min_wave")));
                entries++;
            }
            _log.info("載入波次設定: {}張地圖 / {}種怪 ({}ms)",
                    _configs.size(), entries, timer.get());
        } catch (SQLException e) {
            _log.error("載入波次設定失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(con);
        }
    }

    /** 取某張地圖的波次設定；沒設定或已停用時回 {@code null}。 */
    public WaveConfigTemplate getConfig(int mapId) {
        WaveConfigTemplate t = _configs.get(mapId);
        return t != null && t._enabled ? t : null;
    }

    /**
     * 目前唯一啟用的波次地圖；沒有回 -1。
     * <p>
     * 波次一次只跑一張圖 —— {@link com.xin.server.model.WaveManager} 的狀態
     * （第幾波、剩幾隻）是單一份的，多張圖同時跑會互相覆蓋。
     */
    public int activeMapId() {
        for (WaveConfigTemplate t : _configs.values()) {
            if (t._enabled) {
                return t._mapId;
            }
        }
        return -1;
    }
}
