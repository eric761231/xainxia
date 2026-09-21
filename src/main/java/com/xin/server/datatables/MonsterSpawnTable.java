package com.xin.server.datatables;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.NpcInstance;
import com.xin.server.template.SpawnTemplate;
import com.xin.server.types.NpcType;
import com.xin.util.PerformanceTimer;

/**
 * 怪物生成點（DB 表 {@code spawnlist_monster}）。
 * <p>
 * 與 NPC 分開的理由：怪物會死、會重生（{@code respawn_delay}），之後還會有
 * 掉落、經驗、仇恨範圍等只屬於怪物的設定，不該讓 NPC 表背著這些欄位。
 * 怪物死亡後由 {@link com.xin.server.model.MonsterSpawner} 依生成點 id 回來查重生秒數。
 */
public class MonsterSpawnTable {

    private static final Logger _log = LoggerFactory.getLogger(MonsterSpawnTable.class);

    static final String TABLE = "spawnlist_monster";

    private static MonsterSpawnTable _instance;

    private final Map<Integer, SpawnTemplate> _byId = new HashMap<>();
    private final Map<Integer, List<SpawnTemplate>> _byMap = new HashMap<>();

    public static MonsterSpawnTable get() {
        if (_instance == null) {
            _instance = new MonsterSpawnTable();
        }
        return _instance;
    }

    /** 重新從 DB 載入（GM 熱更新用；已生成的怪物下次重生才套用新的延遲）。 */
    public static void reload() {
        _instance = new MonsterSpawnTable();
    }

    private MonsterSpawnTable() {
        PerformanceTimer timer = new PerformanceTimer();
        for (SpawnTemplate s : SpawnTableSupport.load(TABLE, "npc_id", true)) {
            _byId.put(s._id, s);
            _byMap.computeIfAbsent(s._mapId, k -> new ArrayList<>()).add(s);
        }
        _log.info("載入怪物生成點: " + _byId.size() + "筆 (" + timer.get() + "ms)");
    }

    /** 生成所有怪物。必須在 {@link NpcTable} 載入後呼叫。 */
    public void spawnAll() {
        PerformanceTimer timer = new PerformanceTimer();
        int made = 0;
        int skipped = 0;
        for (SpawnTemplate s : _byId.values()) {
            if (isSafeMap(s._mapId)) {
                _log.warn("{} id={}（{}）位於安全區地圖 {}，怪物不在安全區生成，已略過",
                        TABLE, s._id, s._name, s._mapId);
                skipped += s._count;
                continue;
            }
            boolean warned = false;
            for (int i = 0; i < s._count; i++) {
                NpcInstance npc = spawnOne(s);
                if (npc == null) {
                    skipped++;
                    continue;
                }
                if (!warned && !NpcType.isAttackable(npc.getType())) {
                    _log.warn("{} id={} 使用非怪物模板 {}（{}），應移到 spawnlist_npc",
                            TABLE, s._id, s._npcId, s._name);
                    warned = true;
                }
                made++;
            }
        }
        _log.info("生成怪物 " + made + "隻"
                + (skipped > 0 ? " / 跳過 " + skipped + "隻" : "")
                + " (" + timer.get() + "ms)");
    }

    /**
     * 依一筆生成點生出一隻怪（開服與重生共用）：在範圍內找可走的位置、設定家與面向，
     * 並記住生成點編號 —— 重生延遲寫在那一筆上，死掉時靠這個編號回來查。
     *
     * @return 找不到位置或模板時回傳 {@code null}
     */
    public NpcInstance spawnOne(SpawnTemplate s) {
        if (isSafeMap(s._mapId)) {
            return null;   // 安全區（例如洞府）不生怪：玩家的家不該冒出會打人的東西
        }
        NpcInstance npc = SpawnTableSupport.placeNpc(s);
        if (npc != null) {
            npc.setSpawnId(s._id);
        }
        return npc;
    }

    private static boolean isSafeMap(int mapId) {
        com.xin.server.template.MapTemplate map = MapTable.get().getMap(mapId);
        return map != null && map._safeZone;
    }

    /** 依生成點 id 取得設定；查無時回傳 {@code null}。 */
    public SpawnTemplate getSpawn(int id) {
        return _byId.get(id);
    }

    public List<SpawnTemplate> getSpawnsByMap(int mapId) {
        List<SpawnTemplate> list = _byMap.get(mapId);
        return list != null ? list : Collections.<SpawnTemplate>emptyList();
    }

    public Collection<SpawnTemplate> getAll() {
        return _byId.values();
    }
}
