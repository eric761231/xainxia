package com.xin.server.world;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

import com.xin.server.model.instance.PropertyInstance;

/** 世界場景物件索引（對齊 {@link WorldNpc} 的形）。 */
public final class WorldProperty {

    private static WorldProperty _instance;

    private final ConcurrentHashMap<Long, PropertyInstance> _properties = new ConcurrentHashMap<>();

    public static WorldProperty get() {
        if (_instance == null) {
            _instance = new WorldProperty();
        }
        return _instance;
    }

    public void put(long objId, PropertyInstance property) {
        _properties.put(objId, property);
    }

    public void remove(long objId) {
        _properties.remove(objId);
    }

    public PropertyInstance get(long objId) {
        return _properties.get(objId);
    }

    /** 全世界所有場景物件。 */
    public Collection<PropertyInstance> getAll() {
        return _properties.values();
    }

    /** 取得指定地圖上的所有場景物件（供 S_PROPERTY_PACK 推送）。 */
    public List<PropertyInstance> getPropertiesByMap(int mapId) {
        List<PropertyInstance> list = new ArrayList<>();
        for (PropertyInstance property : _properties.values()) {
            if (property.getMapId() == mapId) {
                list.add(property);
            }
        }
        return list;
    }
}
