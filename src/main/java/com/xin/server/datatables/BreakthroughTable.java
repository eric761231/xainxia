package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.template.BreakthroughTemplate;
import com.xin.server.template.BreakthroughTemplate.Requirement;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 境界突破條件表（對應 DB 表 {@code breakthrough_requirement}）。
 * <p>
 * 儲存各境界突破所需道具（ID 陣列）、護體道具、基礎成功機率與護體加成機率，
 * 由 {@link BreakthroughTemplate#getRequirement(int)} 委派查詢。
 * 資料來源見 {@code sql/game_data_v2.sql}（建表） + {@code sql/game_data_v4.sql}（欄位遷移）。
 */
public class BreakthroughTable {

    private static final Logger _log = LoggerFactory.getLogger(BreakthroughTable.class);

    private static BreakthroughTable _instance;

    /** key = from_stage（突破前境界編號） */
    private final static HashMap<Integer, Requirement> _byFromStage = new HashMap<>();

    public static BreakthroughTable get() {
        if (_instance == null) {
            _instance = new BreakthroughTable();
        }
        return _instance;
    }

    /**
     * 重新從 DB 載入突破條件資料（用於 GM 熱更新）。
     * 先清空快取再重建單例，確保舊資料不殘留。
     */
    public static void reload() {
        _byFromStage.clear();
        _instance = new BreakthroughTable();
    }

    private BreakthroughTable() {
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
                    "SELECT from_stage, to_stage, required_item_ids, protect_item_ids, "
                            + "max_realm_level, base_success_rate, increase_success_rate "
                            + "FROM breakthrough_set");
            rs = ps.executeQuery();
            while (rs.next()) {
                int[]   requiredIds     = parseIds(rs.getString("required_item_ids"));
                int[]   protectIds      = parseIds(rs.getString("protect_item_ids"));
                int     maxRealmLevel   = rs.getInt("max_realm_level");
                int     baseRate        = rs.getInt("base_success_rate");
                int     increaseRate    = rs.getInt("increase_success_rate");
                Requirement req = BreakthroughTemplate.createRequirement(
                        rs.getInt("from_stage"),
                        rs.getInt("to_stage"),
                        requiredIds, protectIds,
                        maxRealmLevel, baseRate, increaseRate);
                _byFromStage.put(rs.getInt("from_stage"), req);
            }
        } catch (SQLException e) {
            _log.error("載入境界突破系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入境界突破系統: " + _byFromStage.size() + "筆 (" + timer.get() + "ms)");
    }

    /**
     * 取得指定境界（fromStage）的突破需求。
     * 若查無資料（DB 尚未設定此境界）則回傳 {@code null}。
     */
    public Requirement getRequirement(int fromStage) {
        return _byFromStage.get(fromStage);
    }

    /**
     * 解析逗號分隔的道具 ID 字串為 int 陣列。
     * 空字串或全空白字串回傳空陣列。
     */
    private static int[] parseIds(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return new int[0];
        }
        String[] parts = raw.split(",");
        int[] ids = new int[parts.length];
        for (int i = 0; i < parts.length; i++) {
            try {
                ids[i] = Integer.parseInt(parts[i].trim());
            } catch (NumberFormatException e) {
                _log.warn("道具 ID 格式錯誤，跳過: '{}'", parts[i]);
                ids[i] = 0;
            }
        }
        return ids;
    }
}
