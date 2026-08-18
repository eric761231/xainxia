package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

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
 * 資料來源見 {@code sql/npc.sql}。
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

    private void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT id, npc_id, `name`, type_name, gfxid, maxhp, maxmp, defense, "
                            + "base_damage, rand_damage, actionList FROM npc");
            rs = ps.executeQuery();
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
                n._actionList = rs.getString("actionList");
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
        npc.setX(x);
        npc.setY(y);
        npc.setMapId(mapId);
        World.get().storeObject(npc);
        return npc;
    }
}
