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
 * 境界統合資料表。
 * <p>
 * 整合三張 DB 表的載入，提供境界所有相關資料的單一查詢入口：
 * <ul>
 *   <li>{@code realm_definition} — 境界名稱與小等級上限</li>
 *   <li>{@code realm_stage_reward} — 突破至新境界的一次性屬性獎勵</li>
 *   <li>{@code realm_level_reward} — 同境界每升一重的屬性獎勵</li>
 * </ul>
 */
public class RealmTable {

    // ── Inner classes ────────────────────────────────────────────────────────

    /**
     * 單境界定義資料（對應 {@code realm_definition}）。
     * 欄位直接公開（L1J 慣例），由 {@link #loadDefinition()} 填入後唯讀使用。
     */
    public static final class RealmDef {
        public int    _stage;           // 境界編號（0=鍛體 … 9=飛昇）
        public String _name;            // 境界名稱（顯示用）
        public int    _levelsPerRealm;  // 此境界的小等級上限

        public RealmDef() {
        }
    }

    /**
     * 單筆境界突破獎勵資料（對應 {@code realm_stage_reward}）。
     * 欄位直接公開，由 {@link #loadStageReward()} 填入後唯讀使用。
     */
    public static final class StageBonus {
        public int _maxHp;    // HP 上限加成
        public int _maxMp;    // MP 上限加成
        public int _defense;  // 防禦加成
        public int _attack;   // 攻擊加成

        public StageBonus() {
        }
    }

    /**
     * 單筆重級獎勵資料（對應 {@code realm_level_reward}）。
     * 欄位直接公開，由 {@link #loadLevelReward()} 填入後唯讀使用。
     */
    public static final class LevelBonus {
        public int _maxHp;    // HP 上限加成
        public int _maxMp;    // MP 上限加成
        public int _defense;  // 防禦加成
        public int _attack;   // 攻擊加成

        public LevelBonus() {
        }
    }

    // ── Singleton & cache ────────────────────────────────────────────────────

    private static final Logger _log = LoggerFactory.getLogger(RealmTable.class);

    private static RealmTable _instance;

    /** key = stage */
    private final static HashMap<Integer, RealmDef>   _byStage     = new HashMap<>();
    /** key = to_stage（突破後境界編號） */
    private final static HashMap<Integer, StageBonus> _stageBonus  = new HashMap<>();
    /** key = "realmStage:realmLevel" */
    private final static HashMap<String, LevelBonus>  _levelBonus  = new HashMap<>();

    public static RealmTable get() {
        if (_instance == null) {
            _instance = new RealmTable();
        }
        return _instance;
    }

    /**
     * 重新從 DB 載入所有境界資料（用於 GM 熱更新）。
     * 先清空快取再重建單例，確保舊資料不殘留。
     */
    public static void reload() {
        _byStage.clear();
        _stageBonus.clear();
        _levelBonus.clear();
        _instance = new RealmTable();
    }

    private RealmTable() {
        load();
    }

    // ── Load ─────────────────────────────────────────────────────────────────

    private void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        loadDefinition();
        loadStageReward();
        loadLevelReward();
        _log.info("載入境界設定系統: 定義" + _byStage.size() + "筆 / 突破獎勵" + _stageBonus.size()
                + "筆 / 重級獎勵" + _levelBonus.size() + "筆 (" + timer.get() + "ms)");
    }

    /** 載入境界名稱與小等級上限（{@code realm_definition}）。 */
    private void loadDefinition() {
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT `stage`, `name`, `levels_per_realm` FROM `realm_definition`");
            rs = ps.executeQuery();
            while (rs.next()) {
                RealmDef def = new RealmDef();
                def._stage          = rs.getInt("stage");
                def._name           = rs.getString("name");
                def._levelsPerRealm = rs.getInt("levels_per_realm");
                _byStage.put(def._stage, def);
            }
        } catch (SQLException e) {
            _log.error("載入境界設定系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /** 載入境界突破一次性獎勵（{@code realm_stage_reward}）。 */
    private void loadStageReward() {
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT to_stage, bonus_max_hp, bonus_max_mp, bonus_defense, bonus_attack "
                            + "FROM realm_stage_reward");
            rs = ps.executeQuery();
            while (rs.next()) {
                StageBonus bonus = new StageBonus();
                bonus._maxHp   = rs.getInt("bonus_max_hp");
                bonus._maxMp   = rs.getInt("bonus_max_mp");
                bonus._defense = rs.getInt("bonus_defense");
                bonus._attack  = rs.getInt("bonus_attack");
                _stageBonus.put(rs.getInt("to_stage"), bonus);
            }
        } catch (SQLException e) {
            _log.error("載入境界突破獎勵系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /** 載入同境界重級獎勵（{@code realm_level_reward}）。 */
    private void loadLevelReward() {
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT realm_stage, realm_level, bonus_max_hp, bonus_max_mp, "
                            + "bonus_defense, bonus_attack FROM realm_level_reward");
            rs = ps.executeQuery();
            while (rs.next()) {
                LevelBonus bonus = new LevelBonus();
                bonus._maxHp   = rs.getInt("bonus_max_hp");
                bonus._maxMp   = rs.getInt("bonus_max_mp");
                bonus._defense = rs.getInt("bonus_defense");
                bonus._attack  = rs.getInt("bonus_attack");
                _levelBonus.put(levelKey(rs.getInt("realm_stage"), rs.getInt("realm_level")), bonus);
            }
        } catch (SQLException e) {
            _log.error("載入重級獎勵系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    // ── Query ─────────────────────────────────────────────────────────────────

    /**
     * 取得指定境界的顯示名稱。
     * 若 DB 查無此境界，fallback 回傳 {@code "?"}.
     */
    public String getName(int stage) {
        RealmDef def = _byStage.get(stage);
        return def != null ? def._name : "?";
    }

    /**
     * 取得指定境界的小等級上限（達到才可嘗試突破下一境界）。
     * 若 DB 查無此境界，fallback 回傳 10。
     */
    public int getLevelsPerRealm(int stage) {
        RealmDef def = _byStage.get(stage);
        return def != null ? def._levelsPerRealm : 10;
    }

    /**
     * 累計 to_stage &lt;= currentStage 的所有突破獎勵，回傳合計值。
     * 用於 {@link com.xin.server.util.CombatStatCalculator} 計算角色屬性基礎值。
     */
    public StageBonus sumStageBonus(int currentStage) {
        StageBonus total = new StageBonus();
        for (int stage = 1; stage <= currentStage; stage++) {
            StageBonus bonus = _stageBonus.get(stage);
            if (bonus != null) {
                total._maxHp   += bonus._maxHp;
                total._maxMp   += bonus._maxMp;
                total._defense += bonus._defense;
                total._attack  += bonus._attack;
            }
        }
        return total;
    }

    /**
     * 累計目前境界 level 2 至 currentLevel 的所有重級獎勵，回傳合計值。
     * （第 1 重為基礎狀態，不另給獎勵；從第 2 重起才有加成。）
     */
    public LevelBonus sumLevelBonus(int realmStage, int currentLevel) {
        LevelBonus total = new LevelBonus();
        for (int level = 2; level <= currentLevel; level++) {
            LevelBonus bonus = _levelBonus.get(levelKey(realmStage, level));
            if (bonus != null) {
                total._maxHp   += bonus._maxHp;
                total._maxMp   += bonus._maxMp;
                total._defense += bonus._defense;
                total._attack  += bonus._attack;
            }
        }
        return total;
    }

    private static String levelKey(int realmStage, int realmLevel) {
        return realmStage + ":" + realmLevel;
    }
}
