package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 各等級升級所需經驗值表（對應 DB 表 {@code level_exp}）。
 * <p>
 * 儲存境界內每個小等級升至下一重所需的累計經驗值，
 * 由 {@link com.xin.server.template.LevelExpTemplate#getExpMax(int)} 委派查詢。
 * 資料來源見 {@code sql/game_data_v3.sql}。
 */
public class LevelExpTable {

    private static final Logger _log = LoggerFactory.getLogger(LevelExpTable.class);

    private static LevelExpTable _instance;

    /** key = 境界內等級（1 起算），value = 升至下一重所需經驗值 */
    private final static HashMap<Integer, Integer> _byLevel = new HashMap<>();

    public static LevelExpTable get() {
        if (_instance == null) {
            _instance = new LevelExpTable();
        }
        return _instance;
    }

    /**
     * 重新從 DB 載入經驗值資料（用於 GM 熱更新）。
     * 先清空快取再重建單例，確保舊資料不殘留。
     */
    public static void reload() {
        _byLevel.clear();
        _instance = new LevelExpTable();
    }

    private LevelExpTable() {
        load();
    }

    private void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement("SELECT `level`, `exp_max` FROM `level_exp`");
            rs = ps.executeQuery();
            while (rs.next()) {
                _byLevel.put(rs.getInt("level"), rs.getInt("exp_max"));
            }
        } catch (SQLException e) {
            _log.error("載入等級經驗值設定系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入等級經驗值設定系統: " + _byLevel.size() + "筆 (" + timer.get() + "ms)");
    }

    /**
     * 取得指定境界內等級升至下一重所需的經驗值上限。
     * 若 DB 無此等級資料，fallback 為 {@code level * 100}（線性公式）。
     *
     * @param level 境界內小等級（1 起算）
     * @return 升級所需經驗值上限
     */
    public int getExpMax(int level) {
        return _byLevel.getOrDefault(level, level * 100);
    }
}
