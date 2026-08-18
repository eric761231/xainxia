package com.xin.server.template;

import com.xin.server.types.ItemType;

/**
 * 道具靜態模板（對應 DB 表 {@code item}）。
 * <p>
 * 由 {@link com.xin.server.datatables.ItemTable} 啟動時從 DB 載入後快取，
 * 執行期透過 {@code ItemTable.get().getTemplate(itemId)} 取回此物件，
 * 再以 {@link com.xin.server.model.instance.ItemInstance} 建立執行時實例。
 */
public class ItemTemplate {

    private int _itemId;       // 道具編號
    private String _name;      // 道具名稱
    private int _itemType;     // 道具分類（0=一般道具 1=武器 2=防具，見 ItemType）
    private boolean _stackable; // 是否可堆疊
    private long _maxStack;    // 最大堆疊數量
    private int _useType;      // 使用方式（0=不可使用 1=可使用）
    private int _weaponType;   // 武器類型（item_type=1 時有效）
    private int _minDamage;    // 最小傷害值
    private int _maxDamage;    // 最大傷害值
    private int _hitModifier;  // 命中修正
    private int _armorType;    // 防具部位（item_type=2 時有效：頭/身/手/腳/盾）
    private int _ac;           // 防禦加成（Armor Class）
    private int _damageReduction; // 傷害減少值
    private int _material;     // 材質類型

    public ItemTemplate() {
    }

    // ── getter ──────────────────────────────────────────────────────────────

    public int getItemId() {
        return _itemId;
    }

    public String getName() {
        return _name;
    }

    public int getItemType() {
        return _itemType;
    }

    public boolean isStackable() {
        return _stackable;
    }

    public long getMaxStack() {
        return _maxStack;
    }

    public int getUseType() {
        return _useType;
    }

    public int getWeaponType() {
        return _weaponType;
    }

    public int getMinDamage() {
        return _minDamage;
    }

    public int getMaxDamage() {
        return _maxDamage;
    }

    public int getHitModifier() {
        return _hitModifier;
    }

    public int getArmorType() {
        return _armorType;
    }

    public int getAc() {
        return _ac;
    }

    public int getDamageReduction() {
        return _damageReduction;
    }

    public int getMaterial() {
        return _material;
    }

    // ── setter ──────────────────────────────────────────────────────────────

    public void setItemId(int i) {
        _itemId = i;
    }

    public void setName(String s) {
        _name = s;
    }

    public void setItemType(int i) {
        _itemType = i;
    }

    public void setStackable(boolean b) {
        _stackable = b;
    }

    public void setMaxStack(long l) {
        _maxStack = l;
    }

    public void setUseType(int i) {
        _useType = i;
    }

    public void setWeaponType(int i) {
        _weaponType = i;
    }

    public void setMinDamage(int i) {
        _minDamage = i;
    }

    public void setMaxDamage(int i) {
        _maxDamage = i;
    }

    public void setHitModifier(int i) {
        _hitModifier = i;
    }

    public void setArmorType(int i) {
        _armorType = i;
    }

    public void setAc(int i) {
        _ac = i;
    }

    public void setDamageReduction(int i) {
        _damageReduction = i;
    }

    public void setMaterial(int i) {
        _material = i;
    }

    // ── 判斷方法 ──────────────────────────────────────────────────────────────

    /** 是否為武器（item_type = 1） */
    public boolean isWeapon() {
        return _itemType == ItemType.WEAPON;
    }

    /** 是否為防具（item_type = 2） */
    public boolean isArmor() {
        return _itemType == ItemType.ARMOR;
    }
}
