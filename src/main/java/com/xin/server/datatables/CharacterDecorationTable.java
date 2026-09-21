package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.DecorationInstance;
import com.xin.server.template.PropertyTemplate;
import com.xin.util.DatabaseFactory;
import com.xin.util.SQLUtil;

/**
 * 角色洞府裝飾（對應 DB 表 {@code character_decoration}）。
 * <p>
 * 與其他 DataTable 不同，本表<b>不做全表記憶體快取</b> ——
 * 資料屬於個別角色且會頻繁增刪，改為進圖時依角色載入、
 * 放置／移除時即時寫回，避免快取與 DB 不同步。
 * 資料來源見 {@code sql/schema_all.sql}。
 */
public class CharacterDecorationTable {

    private static final Logger _log = LoggerFactory.getLogger(CharacterDecorationTable.class);

    private static CharacterDecorationTable _instance;

    public static CharacterDecorationTable get() {
        if (_instance == null) {
            _instance = new CharacterDecorationTable();
        }
        return _instance;
    }

    private CharacterDecorationTable() {
    }

    /** 載入某角色在某地圖的全部裝飾；查無回傳空 List。 */
    public List<DecorationInstance> load(String charName, int mapId) {
        List<DecorationInstance> list = new ArrayList<>();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "SELECT id, property_id, loc_x, loc_y, offset_x, offset_y "
                            + "FROM character_decoration WHERE char_name = ? AND map_id = ?");
            ps.setString(1, charName);
            ps.setInt(2, mapId);
            rs = ps.executeQuery();
            while (rs.next()) {
                DecorationInstance d = new DecorationInstance();
                d._dbId       = rs.getInt("id");
                d._owner      = charName;
                d._propertyId = rs.getInt("property_id");
                d._mapId      = mapId;
                d._x          = rs.getInt("loc_x");
                d._y          = rs.getInt("loc_y");
                d._offsetX    = rs.getInt("offset_x");
                d._offsetY    = rs.getInt("offset_y");
                applyTemplate(d);
                list.add(d);
            }
        } catch (SQLException e) {
            _log.error("載入角色裝飾失敗 char=" + charName + " map=" + mapId, e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        return list;
    }

    /**
     * 寫入一件裝飾。
     *
     * @return 成功時填好 {@code _dbId} 的實例；失敗回 {@code null}
     */
    public DecorationInstance insert(DecorationInstance d) {
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet keys = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "INSERT INTO character_decoration "
                            + "(char_name, property_id, map_id, loc_x, loc_y, offset_x, offset_y) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, d._owner);
            ps.setInt(2, d._propertyId);
            ps.setInt(3, d._mapId);
            ps.setInt(4, d._x);
            ps.setInt(5, d._y);
            ps.setInt(6, d._offsetX);
            ps.setInt(7, d._offsetY);
            ps.executeUpdate();
            keys = ps.getGeneratedKeys();
            if (keys.next()) {
                d._dbId = keys.getInt(1);
            }
            applyTemplate(d);
            return d;
        } catch (SQLException e) {
            _log.error("寫入角色裝飾失敗 char=" + d._owner + " property=" + d._propertyId, e);
            return null;
        } finally {
            SQLUtil.close(keys);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /**
     * 刪除一件裝飾。
     * <p>
     * 條件同時比對 {@code char_name}，即使呼叫端漏了擁有者檢查，
     * SQL 這層也不會讓人刪掉別人的東西。
     */
    public boolean delete(int dbId, String owner) {
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "DELETE FROM character_decoration WHERE id = ? AND char_name = ?");
            ps.setInt(1, dbId);
            ps.setString(2, owner);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            _log.error("刪除角色裝飾失敗 id=" + dbId + " owner=" + owner, e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /**
     * 搬動一件裝飾到新座標。
     * <p>
     * 與 {@link #delete} 同樣把 {@code char_name} 放進 WHERE ——
     * 越權搬別人的家具在 SQL 這層就不可能成立。
     *
     * @return 確實有一列被更新才回 {@code true}
     */
    public boolean updatePosition(int dbId, String owner, int x, int y) {
        Connection cn = null;
        PreparedStatement ps = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement(
                    "UPDATE character_decoration SET loc_x = ?, loc_y = ? "
                            + "WHERE id = ? AND char_name = ?");
            ps.setInt(1, x);
            ps.setInt(2, y);
            ps.setInt(3, dbId);
            ps.setString(4, owner);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            _log.error("搬動角色裝飾失敗 id=" + dbId + " owner=" + owner, e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
    }

    /** 由 property 模板補上圖片、碰撞、佔格等快取欄位。 */
    private static void applyTemplate(DecorationInstance d) {
        PropertyTemplate t = PropertyTable.get().getTemplate(d._propertyId);
        if (t == null) {
            _log.warn("裝飾指向不存在的場景物件模板: propertyId={}", d._propertyId);
            return;
        }
        d._pngId      = t._pngId;
        d._blocking   = t._blocking;
        d._footprintW = Math.max(1, t._footprintW);
        d._footprintH = Math.max(1, t._footprintH);
        d._viewNote   = t._viewNote;
    }
}
