package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.ItemInstance;
import com.xin.server.template.ItemTemplate;
import com.xin.util.DatabaseFactory;
import com.xin.util.SQLUtil;

/**
 * 角色背包的持久化（對應 DB 表 {@code character_items}）。
 * <p>
 * 在此之前 {@link com.xin.server.inventory.Inventory} 只存在記憶體，登出即消失 ——
 * 所以突破的道具消耗只能永遠放行（見 {@code BreakthroughTemplate} 的 TODO）。
 * <p>
 * 與 {@link CharacterDecorationTable} 同樣<b>不做全表快取</b>：資料屬於個別角色
 * 且會頻繁增刪，改為選角時載入、變動時即時寫回，避免快取與 DB 不同步。
 */
public class CharacterItemTable {

    private static final Logger _log = LoggerFactory.getLogger(CharacterItemTable.class);

    private static CharacterItemTable _instance;

    public static CharacterItemTable get() {
        if (_instance == null) {
            _instance = new CharacterItemTable();
        }
        return _instance;
    }

    private CharacterItemTable() {
    }

    /** 載入某角色的全部道具；查無回傳空 List。 */
    public List<ItemInstance> load(long charObjId) {
        List<ItemInstance> list = new ArrayList<>();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT obj_id, item_id, count, enchant_level, bless, "
                            + "durability, is_equipped, is_identified "
                            + "FROM character_items WHERE char_obj_id = ?");
            ps.setLong(1, charObjId);
            rs = ps.executeQuery();
            while (rs.next()) {
                int itemId = rs.getInt("item_id");
                ItemTemplate temp = ItemTable.get().getTemplate(itemId);
                if (temp == null) {
                    // 模板被刪掉了。跳過而不是丟例外 —— 一件壞道具不該讓角色進不了遊戲。
                    _log.warn("角色{}的道具指向不存在的模板 item_id={}，略過",
                            charObjId, itemId);
                    continue;
                }
                ItemInstance it = new ItemInstance();
                it.setId(rs.getLong("obj_id"));
                it.setItem(temp);
                it.setCount(rs.getLong("count"));
                it.setEnchantLevel(rs.getInt("enchant_level"));
                it.setBless(rs.getInt("bless"));
                it.setDurability(rs.getInt("durability"));
                it.setEquipped(rs.getBoolean("is_equipped"));
                it.setIdentified(rs.getBoolean("is_identified"));
                it.setCharObjId(charObjId);
                list.add(it);
            }
        } catch (SQLException e) {
            _log.error("載入角色道具失敗 charObjId=" + charObjId, e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        return list;
    }

    /** 新增一件道具。 */
    public boolean insert(ItemInstance it) {
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "INSERT INTO character_items (obj_id, char_obj_id, item_id, "
                            + "count, enchant_level, bless, durability, "
                            + "is_equipped, is_identified) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            ps.setLong(1, it.getId());
            ps.setLong(2, it.getCharObjId());
            ps.setInt(3, it.getItemId());
            ps.setLong(4, it.getCount());
            ps.setInt(5, it.getEnchantLevel());
            ps.setInt(6, it.getBless());
            ps.setInt(7, it.getDurability());
            ps.setBoolean(8, it.isEquipped());
            ps.setBoolean(9, it.isIdentified());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            _log.error("寫入角色道具失敗 objId=" + it.getId(), e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /** 更新一件道具的可變欄位（數量、強化、裝備狀態）。 */
    public boolean update(ItemInstance it) {
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "UPDATE character_items SET count = ?, enchant_level = ?, "
                            + "durability = ?, is_equipped = ? WHERE obj_id = ?");
            ps.setLong(1, it.getCount());
            ps.setInt(2, it.getEnchantLevel());
            ps.setInt(3, it.getDurability());
            ps.setBoolean(4, it.isEquipped());
            ps.setLong(5, it.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            _log.error("更新角色道具失敗 objId=" + it.getId(), e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /**
     * 刪除一件道具。
     * <p>
     * 條件同時比對 {@code char_obj_id}，即使呼叫端漏了擁有者檢查，
     * SQL 這層也不會讓人刪掉別人的東西（與 {@code CharacterDecorationTable} 同一原則）。
     */
    public boolean delete(long objId, long charObjId) {
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "DELETE FROM character_items WHERE obj_id = ? AND char_obj_id = ?");
            ps.setLong(1, objId);
            ps.setLong(2, charObjId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            _log.error("刪除角色道具失敗 objId=" + objId, e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }
}
