package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.IdFactoryNpc;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.template.NpcTemplate;
import com.xin.server.types.NpcType;
import com.xin.server.world.World;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * NPC 系統（對應 DB 表 {@code npc}）。
 * <p>
 * 伺服器啟動時呼叫 {@link #get()} 將所有 NPC 靜態模板載入快取，
 * 執行期以 {@link #getTemplate(int)} 取回模板，
 * 再以 {@link #createNpc(int, int, int, int)} 產生執行時 {@link NpcInstance}。
 * 資料來源見 {@code sql/schema_all.sql}。
 */
public class NpcTable {

    private static final Logger _log = LoggerFactory.getLogger(NpcTable.class);

    private static NpcTable _instance;

    /** key = npc_id */
    private static final HashMap<Integer, NpcTemplate> _npcs = new HashMap<>();

    public static NpcTable get() {
        if (_instance == null) {
            _instance = new NpcTable();
        }
        return _instance;
    }

    /** 重新從 DB 載入 NPC 模板（GM 熱更新用）。 */
    public static void reload() {
        _npcs.clear();
        _instance = new NpcTable();
    }

    private NpcTable() {
        load();
    }

    /**
     * 之後才加進 npc 表的欄位：缺少時以 0 代入並警告，而<b>不是</b>讓整批載入失敗。
     * <p>
     * 一個欄位不存在就讓 NPC 系統載入 0 筆，症狀是「地圖上什麼都沒有」，
     * 看起來跟 SQL 完全無關，很難追。見 {@code sql/migrate_npc_ai.sql}。
     */
    private static final String[] OPTIONAL_COLUMNS = {
            "hit", "dodge", "passispeed", "atkspeed", "agro", "agro_range", "is_wander", "ranged", "idle_chat"};

    private void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement("SELECT * FROM npc");
            rs = ps.executeQuery();
            Set<String> columns = DbColumns.of(rs);
            List<String> missing = DbColumns.missing(columns, OPTIONAL_COLUMNS);
            if (!missing.isEmpty()) {
                _log.warn("npc 表缺少欄位 {}，暫用預設值；請執行 sql/migrate_npc_ai.sql", missing);
            }
            while (rs.next()) {
                NpcTemplate n = new NpcTemplate();
                n._id         = rs.getInt("id");
                n._npcId      = rs.getInt("npc_id");
                n._name       = rs.getString("name");
                n._typeName   = rs.getString("type_name");
                n._type       = NpcType.of(n._typeName);
                n._gfxid      = rs.getInt("gfxid");
                n._maxHp      = rs.getInt("maxhp");
                n._maxMp      = rs.getInt("maxmp");
                n._defense    = rs.getInt("defense");
                n._baseDamage = rs.getInt("base_damage");
                n._randDamage = rs.getInt("rand_damage");
                n._hit        = DbColumns.intOr(rs, columns, "hit", 0);
                n._dodge      = DbColumns.intOr(rs, columns, "dodge", 0);
                n._actionList = rs.getString("actionList");
                n._passiSpeed = clampSpeed(n, "passispeed",
                        DbColumns.intOr(rs, columns, "passispeed", NpcTemplate.DEFAULT_PASSI_SPEED));
                n._atkSpeed   = clampSpeed(n, "atkspeed",
                        DbColumns.intOr(rs, columns, "atkspeed", NpcTemplate.DEFAULT_ATK_SPEED));
                n._agro       = DbColumns.intOr(rs, columns, "agro", 1) != 0;
                n._agroRange  = Math.max(0,
                        DbColumns.intOr(rs, columns, "agro_range", NpcTemplate.DEFAULT_AGRO_RANGE));
                n._wander     = DbColumns.intOr(rs, columns, "is_wander", 1) != 0;
                n._ranged     = Math.max(1, DbColumns.intOr(rs, columns, "ranged", 1));
                n._idleChat   = DbColumns.stringOr(rs, columns, "idle_chat", "");
                if (n._npcId <= 0) {
                    _log.warn("NPC 資料序號 " + n._id + " 的 npc_id 無效，已略過");
                    continue;
                }
                _npcs.put(n._npcId, n);
            }
        } catch (SQLException e) {
            _log.error("載入NPC系統失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入NPC系統: " + _npcs.size() + "筆 (" + timer.get() + "ms)");
    }

    /**
     * 速度不可低於 {@link NpcTemplate#MIN_SPEED}：前端走一格至少要 0.4 秒，
     * 伺服器更快的話怪物在畫面上會一直瞬移追趕。
     */
    private static int clampSpeed(NpcTemplate n, String column, int value) {
        if (value < NpcTemplate.MIN_SPEED) {
            _log.warn("npc {}（{}）的 {}={} 低於 {}，已調整為 {}",
                    n._npcId, n._name, column, value, NpcTemplate.MIN_SPEED, NpcTemplate.MIN_SPEED);
            return NpcTemplate.MIN_SPEED;
        }
        return value;
    }

    /** 取得指定 npcId 的靜態模板；查無時回傳 {@code null}。 */
    public NpcTemplate getTemplate(int npcId) {
        return _npcs.get(npcId);
    }

    /**
     * 以模板數值在指定座標建立 NPC 執行時實例並登錄至 World。
     *
     * @return 查無模板時回傳 {@code null}
     */
    public NpcInstance createNpc(int npcId, int x, int y, int mapId) {
        NpcTemplate temp = getTemplate(npcId);
        if (temp == null) {
            _log.warn("找不到 NPC 模板: " + npcId);
            return null;
        }
        NpcInstance npc = new NpcInstance();
        npc.setId(IdFactoryNpc.get().nextId());
        npc.setNpcTemplateId(temp._npcId);
        npc.setName(temp._name);
        npc.setGfxid(temp._gfxid);
        npc.setType(temp._type);
        npc.setMaxHp(temp._maxHp);
        npc.setCurrentHp(temp._maxHp);
        npc.setMaxMp(temp._maxMp);
        npc.setCurrentMp(temp._maxMp);
        npc.setDefense(temp._defense);
        npc.setBaseDamage(temp._baseDamage);
        npc.setRandDamage(temp._randDamage);
        npc.setHit(temp._hit);
        npc.setDodge(temp._dodge);
        npc.setPassiSpeed(temp._passiSpeed);
        npc.setAtkSpeed(temp._atkSpeed);
        npc.setAgro(temp._agro);
        npc.setAgroRange(temp._agroRange);
        npc.setWander(temp._wander);
        npc.setRanged(temp._ranged);
        npc.setIdleChat(temp._idleChat);
        npc.setX(x);
        npc.setY(y);
        npc.setMapId(mapId);
        World.get().storeObject(npc);
        return npc;
    }
}
