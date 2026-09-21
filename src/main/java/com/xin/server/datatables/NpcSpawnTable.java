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
 * NPC 生成點（DB 表 {@code spawnlist_npc}）：可交談、商店、採集等<b>非怪物</b>的 NPC。
 * <p>
 * NPC 不會被打死，所以沒有重生設定。怪物請放 {@code spawnlist_monster}（{@link MonsterSpawnTable}）。
 */
public class NpcSpawnTable {

    private static final Logger _log = LoggerFactory.getLogger(NpcSpawnTable.class);

    static final String TABLE = "spawnlist_npc";

    private static NpcSpawnTable _instance;

    private final Map<Integer, SpawnTemplate> _byId = new HashMap<>();
    private final Map<Integer, List<SpawnTemplate>> _byMap = new HashMap<>();

    public static NpcSpawnTable get() {
        if (_instance == null) {
            _instance = new NpcSpawnTable();
        }
        return _instance;
    }

    /** 重新從 DB 載入（GM 熱更新用；不會移除已生成的 NPC）。 */
    public static void reload() {
        _instance = new NpcSpawnTable();
    }

    private NpcSpawnTable() {
        PerformanceTimer timer = new PerformanceTimer();
        for (SpawnTemplate s : SpawnTableSupport.load(TABLE, "npc_id", false)) {
            _byId.put(s._id, s);
            _byMap.computeIfAbsent(s._mapId, k -> new ArrayList<>()).add(s);
        }
        _log.info("載入 NPC 生成點: " + _byId.size() + "筆 (" + timer.get() + "ms)");
    }

    /** 生成所有 NPC。必須在 {@link NpcTable} 載入後呼叫。 */
    public void spawnAll() {
        PerformanceTimer timer = new PerformanceTimer();
        int made = 0;
        int skipped = 0;
        for (SpawnTemplate s : _byId.values()) {
            boolean warned = false;
            for (int i = 0; i < s._count; i++) {
                NpcInstance npc = SpawnTableSupport.placeNpc(s);
                if (npc == null) {
                    skipped++;
                    continue;
                }
                if (!warned && NpcType.isAttackable(npc.getType())) {
                    // 仍然生成，只是提醒放錯表：放在這裡的怪物死了不會重生
                    _log.warn("{} id={} 使用怪物模板 {}（{}），應移到 spawnlist_monster",
                            TABLE, s._id, s._npcId, s._name);
                    warned = true;
                }
                made++;
            }
        }
        _log.info("生成 NPC " + made + "個"
                + (skipped > 0 ? " / 跳過 " + skipped + "個" : "")
                + " (" + timer.get() + "ms)");
    }

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
