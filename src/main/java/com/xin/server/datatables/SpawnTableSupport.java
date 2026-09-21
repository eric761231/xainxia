package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.NpcInstance;
import com.xin.server.template.SpawnTemplate;
import com.xin.server.world.MapGrid;
import com.xin.server.world.WorldMapGrid;
import com.xin.util.DatabaseFactory;
import com.xin.util.SQLUtil;

/**
 * 三張生成點表（{@code spawnlist_scene}／{@code spawnlist_npc}／{@code spawnlist_monster}）共用的讀取與座標工具。
 * 三張表欄位幾乎相同，只差模板欄位名稱與怪物專屬的 {@code respawn_delay}。
 */
final class SpawnTableSupport {

    private static final Logger _log = LoggerFactory.getLogger(SpawnTableSupport.class);

    private SpawnTableSupport() {
    }

    /**
     * 讀取一張生成點表。
     *
     * @param table          表名（程式內常數，不接受外部輸入）
     * @param templateColumn 模板編號欄位（{@code property_id} 或 {@code npc_id}）
     * @param withRespawn    是否讀取 {@code respawn_delay}（只有怪物表有）
     */
    static List<SpawnTemplate> load(String table, String templateColumn, boolean withRespawn) {
        List<SpawnTemplate> out = new ArrayList<>();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement("SELECT * FROM `" + table + "`");
            rs = ps.executeQuery();
            // 階段 1 新增的欄位：還沒跑 migration 時用預設值繼續載入
            Set<String> columns = DbColumns.of(rs);
            List<String> missing = templateColumn.equals("property_id")
                    ? List.of()
                    : DbColumns.missing(columns, withRespawn
                            ? new String[] {"respawn_delay_random", "movement_distance", "heading", "spawn_type"}
                            : new String[] {"heading"});
            if (!missing.isEmpty()) {
                _log.warn("{} 缺少欄位 {}，暫用預設值；請執行 sql/migrate_npc_ai.sql", table, missing);
            }
            while (rs.next()) {
                SpawnTemplate s = new SpawnTemplate();
                s._id    = rs.getInt("id");
                s._zone  = rs.getString("zone");
                s._npcId = rs.getInt(templateColumn);
                s._name  = rs.getString("name");
                s._count = rs.getInt("count");
                s._locX  = rs.getInt("locx");
                s._locY  = rs.getInt("locy");
                s._range = rs.getInt("range");
                s._mapId = rs.getInt("mapid");
                s._respawnDelay = withRespawn ? rs.getInt("respawn_delay") : 0;
                s._respawnDelayRandom = DbColumns.intOr(rs, columns, "respawn_delay_random", 0);
                s._movementDistance = DbColumns.intOr(rs, columns, "movement_distance",
                        SpawnTemplate.DEFAULT_MOVEMENT_DISTANCE);
                s._heading = DbColumns.intOr(rs, columns, "heading", SpawnTemplate.DEFAULT_HEADING);
                s._spawnType = DbColumns.intOr(rs, columns, "spawn_type", SpawnTemplate.SPAWN_NORMAL);
                out.add(s);
            }
        } catch (SQLException e) {
            _log.error("載入生成點表 {} 失敗（是否已執行 sql/migrate_spawnlist_split.sql？）", table, e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        return out;
    }

    /** 在 ±range 內找可站位置的最大嘗試次數。 */
    private static final int PLACE_TRIES = 20;

    /**
     * 在生成點中心 ±range 內找一格<b>可以走</b>的位置放一個 NPC／怪物；找不到回傳 {@code null}。
     * <p>
     * 只檢查地圖邊界是不夠的：座標落在牆或擋路的場景物件上時，怪物會被卡死在原地，
     * 而且在畫面上看起來像是「站在牆裡」。
     */
    static NpcInstance placeNpc(SpawnTemplate s) {
        int[] spot = findSpot(s);
        if (spot == null) {
            _log.warn("生成點 id={}（{}）在地圖{} ({},{}) ±{} 內找不到可走的位置，請檢查座標與碰撞",
                    s._id, s._name, s._mapId, s._locX, s._locY, s._range);
            return null;
        }
        NpcInstance npc = NpcTable.get().createNpc(s._npcId, spot[0], spot[1], s._mapId);
        if (npc == null) {
            return null;
        }
        // 家 = 實際生成的位置：脫戰回家與遊走範圍都以它為準
        npc.setHome(s._mapId, spot[0], spot[1]);
        npc.setMovementDistance(s._movementDistance);
        npc.setHeading(headingOf(s));
        return npc;
    }

    /** 生成點的面向；-1 或超出 0..7 的值一律隨機。 */
    private static int headingOf(SpawnTemplate s) {
        return s._heading >= 0 && s._heading <= 7
                ? s._heading
                : ThreadLocalRandom.current().nextInt(8);
    }

    /**
     * 隨機試 {@link #PLACE_TRIES} 次，再退回中心點；全部不可走回傳 {@code null}。
     * 首領（{@code spawn_type=1}）不散佈，只用中心點。
     */
    private static int[] findSpot(SpawnTemplate s) {
        int tries = s._range > 0 && s._spawnType != SpawnTemplate.SPAWN_BOSS ? PLACE_TRIES : 0;
        for (int i = 0; i < tries; i++) {
            int x = randomCoord(s._locX, s._range);
            int y = randomCoord(s._locY, s._range);
            if (isStandable(s._mapId, x, y)) {
                return new int[] {x, y};
            }
        }
        return isStandable(s._mapId, s._locX, s._locY) ? new int[] {s._locX, s._locY} : null;
    }

    /** 在地圖內、可以走、而且沒有別的 NPC 站著（避免兩隻怪生在同一格）。 */
    private static boolean isStandable(int mapId, int x, int y) {
        if (!MapTable.get().isValidCoord(mapId, x, y)) {
            return false;
        }
        MapGrid grid = WorldMapGrid.get().get(mapId);
        return grid != null && grid.isFree(x, y);
    }

    /** 以中心點加上 {@code ±range} 的隨機偏移取得座標；{@code range <= 0} 時直接回傳中心點。 */
    static int randomCoord(int center, int range) {
        if (range <= 0) {
            return center;
        }
        return center + ThreadLocalRandom.current().nextInt(-range, range + 1);
    }

    /** 同 {@link #randomCoord}，但使用指定的亂數源以取得可重現的結果。 */
    static int seededCoord(Random rnd, int center, int range) {
        if (range <= 0) {
            return center;
        }
        return center + rnd.nextInt(range * 2 + 1) - range;
    }
}
