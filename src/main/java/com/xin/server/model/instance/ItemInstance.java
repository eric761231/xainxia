package com.xin.server.model.instance;

import com.xin.server.model.Object;
import com.xin.server.template.ItemTemplate;

/**
 * 物品類控制項（對齊天堂 L1ItemInstance 精簡版）。
 */
public class ItemInstance extends Object {

    private int _itemId;
    private ItemTemplate _item;
    private long _count = 1;
    private int _enchantLevel;
    private int _bless = 1;
    private int _durability;
    private boolean _isEquipped;
    private boolean _isIdentified = true;
    private long _charObjId;

    public int getItemId() {
        return _itemId;
    }

    public void setItemId(int itemId) {
        _itemId = itemId;
    }

    public ItemTemplate getItem() {
        return _item;
    }

    public void setItem(ItemTemplate item) {
        _item = item;
        if (item != null) {
            _itemId = item.getItemId();
        }
    }

    public String getName() {
        return _item != null ? _item.getName() : "";
    }

    public long getCount() {
        return _count;
    }

    public void setCount(long count) {
        _count = count;
    }

    public int getEnchantLevel() {
        return _enchantLevel;
    }

    public void setEnchantLevel(int enchantLevel) {
        _enchantLevel = enchantLevel;
    }

    public int getBless() {
        return _bless;
    }

    public void setBless(int bless) {
        _bless = bless;
    }

    public int getDurability() {
        return _durability;
    }

    public void setDurability(int durability) {
        _durability = durability;
    }

    public boolean isEquipped() {
        return _isEquipped;
    }

    public void setEquipped(boolean equipped) {
        _isEquipped = equipped;
    }

    public boolean isIdentified() {
        return _isIdentified;
    }

    public void setIdentified(boolean identified) {
        _isIdentified = identified;
    }

    public long getCharObjId() {
        return _charObjId;
    }

    public void setCharObjId(long charObjId) {
        _charObjId = charObjId;
    }
}
