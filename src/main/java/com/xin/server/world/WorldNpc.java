package com.xin.server.world;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import com.xin.server.model.instance.NpcInstance;

/**
 * 世界 NPC 物件索引（對齊天堂 WorldNpc）。
 * <p>
 * 另外維護「地圖 → 該圖 NPC」的索引：AI 巡檢與怪物封包每秒都要查某張圖的 NPC，
 * 以前是掃全世界再過濾，NPC 一多就是每秒 O(全世界) 的浪費。
 * NPC 生成後不會換地圖，所以索引只在 put／remove 時維護。
 */
public final class WorldNpc {

    private static WorldNpc _instance;

    private final ConcurrentHashMap<Long, NpcInstance> _npcs = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Integer, Set<Long>> _byMap = new ConcurrentHashMap<>();

    public static WorldNpc get() {
        if (_instance == null) {
            _instance = new WorldNpc();
        }
        return _instance;
    }

    public void put(long objId, NpcInstance npc) {
        _npcs.put(objId, npc);
        _byMap.computeIfAbsent(npc.getMapId(), k -> ConcurrentHashMap.newKeySet()).add(objId);
    }

    public void remove(long objId) {
        NpcInstance npc = _npcs.remove(objId);
        if (npc != null) {
            Set<Long> ids = _byMap.get(npc.getMapId());
            if (ids != null) {
                ids.remove(objId);
            }
        }
    }

    public NpcInstance get(long objId) {
        return _npcs.get(objId);
    }

    /** 全世界所有 NPC。 */
    public Collection<NpcInstance> getAll() {
        return _npcs.values();
    }

    /** 取得指定地圖上的所有 NPC（供 S_NPC_PACK／S_MONSTER_PACK 推送與 AI 巡檢）。 */
    public List<NpcInstance> getNpcsByMap(int mapId) {
        Set<Long> ids = _byMap.get(mapId);
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyList();
        }
        List<NpcInstance> list = new ArrayList<>(ids.size());
        for (Long id : ids) {
            NpcInstance npc = _npcs.get(id);
            if (npc != null) {
                list.add(npc);
            }
        }
        return list;
    }
}
