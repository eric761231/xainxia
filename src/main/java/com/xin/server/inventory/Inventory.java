package com.xin.server.inventory;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

import com.xin.server.model.instance.ItemInstance;

/**
 * 角色背包（對齊天堂 L1Inventory 精簡版，key = 道具 objId）。
 */
public class Inventory {

    private final Map<Long, ItemInstance> _items = new LinkedHashMap<>();

    public Collection<ItemInstance> getItems() {
        return Collections.unmodifiableCollection(_items.values());
    }

    public ItemInstance getItem(long objId) {
        return _items.get(objId);
    }

    public void storeItem(ItemInstance item) {
        if (item != null && item.getId() > 0) {
            _items.put(item.getId(), item);
        }
    }

    public ItemInstance deleteItem(long objId) {
        return _items.remove(objId);
    }

    public int getSize() {
        return _items.size();
    }

    public void clearItems() {
        _items.clear();
    }
}
