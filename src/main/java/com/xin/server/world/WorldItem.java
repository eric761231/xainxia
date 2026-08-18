package com.xin.server.world;

import java.util.concurrent.ConcurrentHashMap;

import com.xin.server.model.instance.ItemInstance;

/** 世界 ITEM 物件索引（對齊天堂 WorldItem）。 */
public final class WorldItem {

    private static WorldItem _instance;

    private final ConcurrentHashMap<Long, ItemInstance> _items = new ConcurrentHashMap<>();

    public static WorldItem get() {
        if (_instance == null) {
            _instance = new WorldItem();
        }
        return _instance;
    }

    public void put(long objId, ItemInstance item) {
        _items.put(objId, item);
    }

    public void remove(long objId) {
        _items.remove(objId);
    }

    public ItemInstance get(long objId) {
        return _items.get(objId);
    }
}
