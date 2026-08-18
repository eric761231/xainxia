package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.template.SpawnTemplate;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * NPC 生成點系統（對應 DB 表 {@code spawnlist}）。
 * <p>
 * 每筆資料描述某地圖上一組 NPC 的出生座標、數量與散佈範圍。
 * 本表只負責載入快取，實際生成由呼叫端搭配
 * {@link NpcTable#createNpc(int, int, int, int)} 進行。
 * 資料來源見 {@code sql/spawnlist.sql}。
 */
public class SpawnTable {

    private static final Logger _log = LoggerFactory.getLogger(SpawnTable.class);

    private static SpawnTable _instance;

    /** key = id */
    private static final HashMap<Integer, SpawnTemplate>       _bySpawnId = new HashMap<>();
    /** key = mapid，value = 該地圖下所有生成點（唯讀 List） */
    private static final HashMap<Integer, List<SpawnTemplate>> _byMapId   = new HashMap<>();

    public static SpawnTable get() {
        if (_instance == null) {
            _instance = new SpawnTable();
        }
        return _instance;
    }

    /** 重新從 DB 載入生成點資料（GM 熱更新用）。 */
    public static void reload() {
        _bySpawnId.clear();
        _byMapId.clear();
        _instance = new SpawnTable();
    }

    private SpawnTable() {
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
                    "SELECT id, zone, npc_id, `name`, `count`, locx, locy, `range`, mapid "
                            + "FROM spawnlist");
            rs = ps.executeQuery();
            while (rs.next()) {
                SpawnTemplate s = new SpawnTemplate();
                s._id    = rs.getInt("id");
                s._zone  = rs.getString("zone");
                s._npcId = rs.getInt("npc_id");
                s._name  = rs.getString("name");
                s._count = rs.getInt("count");
                s._locX  = rs.getInt("locx");
                s._locY  = rs.getInt("locy");
                s._range = rs.getInt("range");
                s._mapId = rs.getInt("mapid");
                _bySpawnId.put(s._id, s);
                _byMapId.computeIfAbsent(s._mapId, k -> new ArrayList<>()).add(s);
            }
        } catch (SQLException e) {
            _log.error("載入NPC生成點系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入NPC生成點系統: " + _bySpawnId.size() + "筆 (" + timer.get() + "ms)");
    }

    /** 依資料序號取得生成點；查無時回傳 {@code null}。 */
    public SpawnTemplate getSpawn(int id) {
        return _bySpawnId.get(id);
    }

    /** 取得指定地圖的所有生成點；該地圖無資料時回傳空 List。 */
    public List<SpawnTemplate> getSpawnsByMap(int mapId) {
        List<SpawnTemplate> list = _byMapId.get(mapId);
        return list != null ? list : Collections.<SpawnTemplate>emptyList();
    }

    /** 取得全部生成點（供啟動時批次生成使用）。 */
    public Collection<SpawnTemplate> getAll() {
        return _bySpawnId.values();
    }
}
