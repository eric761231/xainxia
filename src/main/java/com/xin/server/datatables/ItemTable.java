package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.IdFactory;
import com.xin.server.model.instance.ItemInstance;
import com.xin.server.template.ItemTemplate;
import com.xin.server.world.World;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 道具資料表（對應 DB 表 {@code item}，統一存放一般道具、武器、防具）。
 * <p>
 * 伺服器啟動時呼叫 {@link #get()} 初始化並快取，
 * 執行期透過 {@link #getTemplate(int)} 取回靜態模板，
 * 再以 {@link #createItem(int)} 產生執行時 {@link ItemInstance}。
 */
public class ItemTable {

    private static final Logger _log = LoggerFactory.getLogger(ItemTable.class);

    private static ItemTable _instance;

    /** key = item_id，存放所有已載入的道具靜態模板 */
    private final static HashMap<Integer, ItemTemplate> _allTemplates = new HashMap<>();

    public static ItemTable get() {
        if (_instance == null) {
            _instance = new ItemTable();
        }
        return _instance;
    }

    /**
     * 重新從 DB 載入道具資料（用於 GM 熱更新）。
     * 先清空快取再重建單例，確保舊資料不殘留。
     */
    public static void reload() {
        _allTemplates.clear();
        _instance = new ItemTable();
    }

    private ItemTable() {
        load();
    }

    private void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT item_id, name, item_type, stackable, max_stack, use_type, "
                            + "weapon_type, min_damage, max_damage, hit_modifier, "
                            + "armor_type, ac, damage_reduction, material FROM item");
            rs = ps.executeQuery();
            while (rs.next()) {
                ItemTemplate item = new ItemTemplate();
                item.setItemId(rs.getInt("item_id"));
                item.setName(rs.getString("name"));
                item.setItemType(rs.getInt("item_type")); // 道具類型
                item.setStackable(rs.getInt("stackable") == 1);
                item.setMaxStack(rs.getLong("max_stack"));
                item.setUseType(rs.getInt("use_type")); // 使用類型
                item.setWeaponType(rs.getInt("weapon_type")); // 武器類型
                item.setMinDamage(rs.getInt("min_damage"));
                item.setMaxDamage(rs.getInt("max_damage"));
                item.setHitModifier(rs.getInt("hit_modifier"));
                item.setArmorType(rs.getInt("armor_type")); // 防具類型
                item.setAc(rs.getInt("ac"));
                item.setDamageReduction(rs.getInt("damage_reduction"));
                item.setMaterial(rs.getInt("material"));
                _allTemplates.put(item.getItemId(), item);
            }
        } catch (SQLException e) {
            _log.error("載入道具系統資料失敗，使用硬編碼備援", e);
            loadFallback();
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        if (_allTemplates.isEmpty()) {
            loadFallback();
        }
        _log.info("載入道具系統資料: " + _allTemplates.size() + "筆 (" + timer.get() + "ms)");
    }

    /** DB 無資料時的硬編碼備援（最小可運行資料集）。 */
    private void loadFallback() {
        ItemTemplate coin = new ItemTemplate();
        coin.setItemId(40308);
        coin.setName("金幣");
        coin.setItemType(0);
        coin.setStackable(true);
        coin.setMaxStack(2_000_000_000L);
        register(coin);

        ItemTemplate potion = new ItemTemplate();
        potion.setItemId(40010);
        potion.setName("治癒藥水");
        potion.setItemType(0);
        potion.setStackable(true);
        potion.setMaxStack(1000);
        potion.setUseType(1);
        register(potion);

        ItemTemplate sword = new ItemTemplate();
        sword.setItemId(4);
        sword.setName("長劍");
        sword.setItemType(1);
        sword.setStackable(false);
        sword.setMaxStack(1);
        sword.setWeaponType(1);
        sword.setMinDamage(5);
        sword.setMaxDamage(12);
        sword.setHitModifier(2);
        register(sword);
    }

    private void register(ItemTemplate item) {
        _allTemplates.put(item.getItemId(), item);
    }

    /** 取得指定 itemId 的靜態模板，不存在回傳 {@code null}。 */
    public ItemTemplate getTemplate(int itemId) {
        return _allTemplates.get(itemId);
    }

    /** 以自動分配 objId 建立一個數量為 1 的道具執行時實例。 */
    public ItemInstance createItem(int itemId) {
        ItemTemplate temp = getTemplate(itemId);
        if (temp == null) {
            return null;
        }
        ItemInstance item = new ItemInstance();
        item.setId(IdFactory.get().nextId());
        item.setItem(temp);
        item.setCount(1);
        World.get().storeObject(item);
        return item;
    }

    /** 以指定 objId 建立道具執行時實例（用於從 DB 還原已持久化的道具）。 */
    public ItemInstance createItem(int itemId, long objId) {
        ItemTemplate temp = getTemplate(itemId);
        if (temp == null) {
            return null;
        }
        ItemInstance item = new ItemInstance();
        item.setId(objId);
        item.setItem(temp);
        item.setCount(1);
        World.get().storeObject(item);
        return item;
    }
}
