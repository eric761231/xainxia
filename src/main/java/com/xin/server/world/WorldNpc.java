package com.xin.server.world;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

import com.xin.server.model.instance.NpcInstance;

/** 世界 NPC 物件索引（對齊天堂 WorldNpc）。 */
public final class WorldNpc {

    private static WorldNpc _instance;

    private final ConcurrentHashMap<Long, NpcInstance> _npcs = new ConcurrentHashMap<>();

    public static WorldNpc get() {
        if (_instance == null) {
            _instance = new WorldNpc();
        }
        return _instance;
    }

    public void put(long objId, NpcInstance npc) {
        _npcs.put(objId, npc);
    }

    public void remove(long objId) {
        _npcs.remove(objId);
    }

    public NpcInstance get(long objId) {
        return _npcs.get(objId);
    }

    /** 全世界所有 NPC。 */
    public Collection<NpcInstance> getAll() {
        return _npcs.values();
    }

    /** 取得指定地圖上的所有 NPC（供 S_OBJECT_LIST 推送）。 */
    public List<NpcInstance> getNpcsByMap(int mapId) {
        List<NpcInstance> list = new ArrayList<>();
        for (NpcInstance npc : _npcs.values()) {
            if (npc.getMapId() == mapId) {
                list.add(npc);
            }
        }
        return list;
    }
}
