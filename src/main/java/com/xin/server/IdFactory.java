package com.xin.server;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.concurrent.atomic.AtomicLong;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 持久物件 ID 分配器（對齊天堂 IdFactory）。
 * <p>
 * 角色、道具、倉庫等持久物件共用同一序列；只遞增、不回收。
 * obj_id 由程式分配，禁止 DB AUTO_INCREMENT。
 * <p>
 * 持久化策略（雙重保障）：
 * <ol>
 *   <li>{@link #load()} — 啟動時從 {@code id_sequence} 表讀取上次寫回的 next_id，
 *       同時掃描所有 entity 表取最大值，二者取大，確保不衝突。</li>
 *   <li>{@link #save()} — 正常關機時將當前 next_id 寫回 {@code sequence_id}，
 *       下次啟動無需全表掃描即可快速恢復。</li>
 * </ol>
 */
public class IdFactory {

    private static final Logger _log = LoggerFactory.getLogger(IdFactory.class);

    /** 序列名稱（對應 id_sequence.name） */
    private static final String SEQ_NAME = "obj_id";

    /** 最小編號（天堂 0x2710 = 10000） */
    private static final long MIN_ID = 10_000L;

    private static IdFactory _instance;

    private final Object _monitor = new Object();
    private AtomicLong _nextId;

    public static IdFactory get() {
        if (_instance == null) {
            _instance = new IdFactory();
        }
        return _instance;
    }

    /** 以原子方式將目前值加 1 並回傳（分配前的值）。 */
    public long nextId() {
        synchronized (_monitor) {
            return _nextId.getAndIncrement();
        }
    }

    /** 取得下一個將被分配的編號（不含遞增）。 */
    public long maxId() {
        synchronized (_monitor) {
            return _nextId.get();
        }
    }

    /**
     * 啟動時從 DB 載入起始 ID。
     * <p>
     * 取以下三者的最大值作為下一號：
     * <ol>
     *   <li>{@code sequence_id} 表中記錄的上次關機值（正常關機後有效）</li>
     *   <li>{@code characters} 表 MAX(obj_id) + 1（entity 掃描兜底）</li>
     *   <li>{@link #MIN_ID}（絕對下限 10000）</li>
     * </ol>
     */
    public void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        long seqId = readSequenceTable();
        long entityMax = readEntityMaxId();
        long id = Math.max(MIN_ID, Math.max(seqId, entityMax));
        synchronized (_monitor) {
            _nextId = new AtomicLong(id);
        }
        _log.info("載入伺服器流水編號管理系統：seq={} entityMax={} → 下一號={} ({}ms)",
                seqId, entityMax, id, timer.get());
    }

    /**
     * 正常關機時將當前 next_id 寫回 {@code id_sequence}。
     * 由 {@link GameServer} 在 {@code finally} 區塊中呼叫。
     */
    public void save() {
        long current;
        synchronized (_monitor) {
            current = _nextId == null ? MIN_ID : _nextId.get();
        }
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "INSERT INTO `sequence_id` (`name`, `next_id`) VALUES (?, ?) "
                            + "ON DUPLICATE KEY UPDATE `next_id` = VALUES(`next_id`)");
            ps.setString(1, SEQ_NAME);
            ps.setLong(2, current);
            ps.executeUpdate();
            _log.info("ID 序列已寫回 DB：{}={}", SEQ_NAME, current);
        } catch (SQLException e) {
            _log.error("ID 序列寫回失敗（下次啟動將改用 entity 掃描兜底）", e);
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    // ── 私有輔助方法 ──────────────────────────────────────────────────────────

    /** 從 {@code id_sequence} 表讀取上次寫回的 next_id；查無記錄時回傳 MIN_ID。 */
    private long readSequenceTable() {
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement("SELECT `next_id` FROM `sequence_id` WHERE `name` = ?");
            ps.setString(1, SEQ_NAME);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getLong("next_id");
            }
        } catch (SQLException e) {
            _log.warn("讀取 id_sequence 失敗，改用 entity 掃描兜底", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        return MIN_ID;
    }

    /**
     * 掃描所有 entity 表，取 MAX(obj_id) + 1。
     * 新增道具 / 倉庫等持久表後，在此 UNION 中補充對應欄位。
     */
    private long readEntityMaxId() {
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT COALESCE(MAX(obj_id), 0) + 1 AS next_id FROM ("
                            + "  SELECT obj_id FROM `characters`"
                            // TODO: 待 character_items 表建立後補充：
                            // + "  UNION ALL SELECT obj_id FROM `character_items`"
                            + ") AS t");
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getLong("next_id");
            }
        } catch (SQLException e) {
            _log.error("掃描 entity 表最大 ID 失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        return MIN_ID;
    }
}
