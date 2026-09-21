package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.HashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.IdFactoryNpc;
import com.xin.server.model.instance.PropertyInstance;
import com.xin.server.template.PropertyTemplate;
import com.xin.server.world.World;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * 場景物件設定表（對應 DB 表 {@code property}）。
 * <p>
 * 保存每種場景物件的圖片、顯示名稱與互動設定，供生成實例與封包推送使用。
 * 實際生成由 {@link SceneSpawnTable#spawnAll()} 依 {@code spawnlist_scene}
 * 的設定呼叫 {@link #createProperty(int, int, int, int)}。
 * 資料來源見 {@code sql/schema_all.sql}。
 *
 * @author user
 */
public class PropertyTable {

    private static final Logger _log = LoggerFactory.getLogger(PropertyTable.class);

    private static PropertyTable _instance;

    /** key = property.id */
    private final HashMap<Integer, PropertyTemplate> _properties = new HashMap<>();

    public static PropertyTable get() {
        if (_instance == null) {
            _instance = new PropertyTable();
        }
        return _instance;
    }

    /** 重新從 DB 載入場景物件設定（GM 熱更新用）。 */
    public static void reload() {
        _instance = new PropertyTable();
    }

    private PropertyTable() {
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
                    "SELECT id, pngid, blocking, footprint_w, footprint_h, min_gap, "
                            + "placeable, placement, "
                            + "view_note, `action`, action_type, `value`, bubble_text "
                            + "FROM property");
            rs = ps.executeQuery();
            while (rs.next()) {
                PropertyTemplate p = new PropertyTemplate();
                p._id         = rs.getInt("id");
                p._pngId      = rs.getInt("pngid");
                p._blocking   = rs.getBoolean("blocking");
                p._footprintW = Math.max(1, rs.getInt("footprint_w"));
                p._footprintH = Math.max(1, rs.getInt("footprint_h"));
                p._minGap     = rs.getInt("min_gap");
                p._placeable  = rs.getBoolean("placeable");
                p._placement  = rs.getString("placement");
                p._viewNote   = rs.getString("view_note");
                p._action     = rs.getBoolean("action");
                p._actionType = rs.getInt("action_type");
                p._value      = rs.getInt("value");
                p._bubbleText = rs.getString("bubble_text");
                _properties.put(p._id, p);
            }
        } catch (SQLException e) {
            _log.error("載入場景物件設定失敗", e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(cn);
        }
        _log.info("載入場景物件設定: " + _properties.size() + "筆 (" + timer.get() + "ms)");
    }

    /** 依編號取得場景物件設定；查無時回傳 {@code null}。 */
    public PropertyTemplate getTemplate(int propertyId) {
        return _properties.get(propertyId);
    }

    /** 取得玩家可自行放置的場景物件（家具清單）。 */
    public java.util.List<PropertyTemplate> getPlaceable() {
        java.util.List<PropertyTemplate> list = new java.util.ArrayList<>();
        for (PropertyTemplate t : _properties.values()) {
            if (t._placeable) {
                list.add(t);
            }
        }
        list.sort((a, b) -> Integer.compare(a._id, b._id));
        return list;
    }

    /** 取得全部場景物件設定。 */
    public Collection<PropertyTemplate> getAll() {
        return _properties.values();
    }

    /**
     * 以模板數值在指定座標建立場景物件執行時實例並登錄至 World。
     *
     * @return 查無模板時回傳 {@code null}
     */
    public PropertyInstance createProperty(int propertyId, int x, int y, int mapId) {
        PropertyTemplate temp = getTemplate(propertyId);
        if (temp == null) {
            _log.warn("找不到場景物件模板: " + propertyId);
            return null;
        }
        PropertyInstance property = new PropertyInstance();
        property.setId(IdFactoryNpc.get().nextId());
        property.setPropertyTemplateId(temp._id);
        property.setName(temp._viewNote);
        property.setPngId(temp._pngId);
        property.setBlocking(temp._blocking);
        property.setFootprintW(temp._footprintW);
        property.setFootprintH(temp._footprintH);
        property.setAction(temp._action);
        property.setActionType(temp._actionType);
        property.setValue(temp._value);
        property.setBubbleText(temp._bubbleText);
        property.setX(x);
        property.setY(y);
        property.setMapId(mapId);
        World.get().storeObject(property);
        return property;
    }
}
