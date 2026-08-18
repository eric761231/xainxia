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
 * 四維素質成長加成表（對應 DB 表 {@code stat_growth_bonus}）。
 * <p>
 * 儲存每點素質（體魄/神識/敏捷/悟性）對各屬性（HP 上限/防禦/命中等）的加成量。
 * 由 {@link com.xin.server.template.CombatStatCalculator} 在計算角色屬性時查詢。
 */
public class StatGrowthBonusTable {

    private static final Logger _log = LoggerFactory.getLogger(StatGrowthBonusTable.class);

    private static StatGrowthBonusTable _instance;

    /** key = "stat_type:bonus_type"，value = 每點素質的加成值 */
    private final static HashMap<String, Integer> _bonuses = new HashMap<>();

    public static StatGrowthBonusTable get() {
        if (_instance == null) {
            _instance = new StatGrowthBonusTable();
        }
        return _instance;
    }

    /**
     * 重新從 DB 載入素質成長加成資料（用於 GM 熱更新）。
     * 先清空快取再重建單例，確保舊資料不殘留。
     */
    public static void reload() {
        _bonuses.clear();
        _instance = new StatGrowthBonusTable();
    }

    private StatGrowthBonusTable() {
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
                    "SELECT stat_type, bonus_type, bonus_per_point FROM stat_growth_bonus");
            rs = ps.executeQuery();
            while (rs.next()) {
                String key = key(rs.getInt("stat_type"), rs.getString("bonus_type"));
                _bonuses.put(key, rs.getInt("bonus_per_point"));
            }
        } catch (SQLException e) {
            _log.error("載入素質成長加成失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入素質成長加成系統: " + _bonuses.size() + "筆 (" + timer.get() + "ms)");
    }

    /**
     * 查詢指定素質類型（{@link com.xin.server.template.StatType}）
     * 在指定加成項目（{@link com.xin.server.template.BonusType}）上每點的加成值。
     * 若查無資料則回傳 0。
     */
    public int getBonus(int statType, String bonusType) {
        return _bonuses.getOrDefault(key(statType, bonusType), 0);
    }

    private static String key(int statType, String bonusType) {
        return statType + ":" + bonusType;
    }
}
