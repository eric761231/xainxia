package com.xin.server.inventory;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.xin.server.model.instance.ItemInstance;

/**
 * 角色背包（對齊天堂 L1Inventory 精簡版，key = 道具 objId）。
 * <p>
 * 疊加規則：可疊加的道具<b>同一個 itemId 只佔一格</b>，數量累加到既有的那一筆；
 * 不可疊加的（武器防具）每一件各自一格。這是查詢與扣除都要遵守的前提 ——
 * 兩處規則不一致的話，會出現「顯示有 3 瓶但扣不掉」這種難查的問題。
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

    // ── 查詢與扣除 ──────────────────────────────────────────────────────────

    /**
     * 找出可以疊加的既有道具；沒有或該道具不可疊加時回 {@code null}。
     * <p>
     * 也會避開已達上限的那一疊 —— 否則 count 會被加到超過 {@code max_stack}。
     */
    public ItemInstance findStackable(int itemId, long adding) {
        for (ItemInstance it : _items.values()) {
            if (it.getItemId() != itemId) {
                continue;
            }
            if (it.getItem() == null || !it.getItem().isStackable()) {
                continue;
            }
            long max = it.getItem().getMaxStack();
            if (max <= 0 || it.getCount() + adding <= max) {
                return it;
            }
        }
        return null;
    }

    /** 該道具的總持有量（跨多疊加總）。 */
    public long countOf(int itemId) {
        long total = 0;
        for (ItemInstance it : _items.values()) {
            if (it.getItemId() == itemId) {
                total += it.getCount();
            }
        }
        return total;
    }

    /** 是否持有足夠數量。 */
    public boolean has(int itemId, long count) {
        return count <= 0 || countOf(itemId) >= count;
    }

    /**
     * 扣除指定數量，回傳被<b>整筆刪除</b>的道具 objId 清單（供通知前端移除）。
     * <p>
     * 數量不足時<b>不扣任何東西</b>並回傳 {@code null} —— 部分扣除會讓玩家
     * 付了代價卻沒拿到結果，比直接失敗糟糕得多。呼叫端要先看回傳值再繼續。
     */
    public List<Long> consume(int itemId, long count) {
        if (count <= 0) {
            return new ArrayList<>();
        }
        if (!has(itemId, count)) {
            return null;
        }

        List<Long> removed = new ArrayList<>();
        long left = count;
        // 先扣數量少的那疊，讓背包格子盡快被釋放
        List<ItemInstance> matched = new ArrayList<>();
        for (ItemInstance it : _items.values()) {
            if (it.getItemId() == itemId) {
                matched.add(it);
            }
        }
        matched.sort((a, b) -> Long.compare(a.getCount(), b.getCount()));

        for (ItemInstance it : matched) {
            if (left <= 0) {
                break;
            }
            long take = Math.min(left, it.getCount());
            it.setCount(it.getCount() - take);
            left -= take;
            if (it.getCount() <= 0) {
                removed.add(it.getId());
            }
        }
        for (Long objId : removed) {
            _items.remove(objId);
        }
        return removed;
    }
}
