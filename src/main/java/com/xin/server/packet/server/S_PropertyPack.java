package com.xin.server.packet.server;

import java.util.List;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.model.instance.DecorationInstance;
import com.xin.server.model.instance.PropertyInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.world.WorldProperty;

/**
 * 場景物件封包（對應 opcode {@code S_PROPERTY_PACK}）。
 * <p>
 * 資料來自 {@code property} 表，經 {@code spawnlist_scene}
 * 的設定生成。{@code actionType}：1=對話、2=採集。
 * <p>
 * {@code footprintW/H} 是<b>地面佔格</b>（碰撞用），不是視覺尺寸；
 * {@code pngid} 對應前端 {@code object_catalog.json} 的物件 id。
 * <p>
 * 注意：{@code bubbleText} <b>不</b>包含在此封包中——整張圖的對話文字沒必要預載，
 * 實際互動時才由 {@link S_BubbleDialog} 單獨送出。
 *
 * <pre>
 * {
 *   "op": "S_PROPERTY_PACK",
 *   "data": {
 *     "mapId": 1,
 *     "properties": [
 *       { "objId": 2000000003, "name": "石碑", "x": 15, "y": 18, "heading": 2,
 *         "propertyId": 1001, "pngid": 1010, "blocking": true,
 *         "footprintW": 1, "footprintH": 1,
 *         "action": true, "actionType": 1, "value": 0 }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_PropertyPack extends ServerBasePacket {

    private S_PropertyPack(int mapId) {
        super(ServerOpcodes.S_PROPERTY_PACK);
        put("mapId", mapId);

        List<PropertyInstance> properties = WorldProperty.get().getPropertiesByMap(mapId);
        ArrayNode arr = newArray();
        for (PropertyInstance property : properties) {
            ObjectNode node = newObject();
            node.put("objId",      property.getId());
            node.put("name",       property.getName());
            node.put("x",          property.getX());
            node.put("y",          property.getY());
            node.put("heading",    property.getHeading());
            node.put("propertyId", property.getPropertyTemplateId());
            node.put("pngid",      property.getPngId());
            node.put("blocking",   property.isBlocking());
            node.put("footprintW", property.getFootprintW());
            node.put("footprintH", property.getFootprintH());
            node.put("offsetX",    0);
            node.put("offsetY",    0);
            node.put("action",     property.isAction());
            node.put("actionType", property.getActionType());
            node.put("value",      property.getValue());
            arr.add(node);
        }
        putArray("properties", arr);
    }

    /**
     * 玩家裝飾版本：欄位與世界物件完全相同，前端因此只需要一條解析路徑，
     * 不必分辨這件東西是企劃擺的還是玩家自己擺的。
     */
    private S_PropertyPack(int mapId, List<DecorationInstance> decorations) {
        super(ServerOpcodes.S_PROPERTY_PACK);
        put("mapId", mapId);

        ArrayNode arr = newArray();
        for (DecorationInstance d : decorations) {
            ObjectNode node = newObject();
            node.put("objId",      d._objId);
            node.put("name",       d._viewNote != null ? d._viewNote : "");
            node.put("x",          d._x);
            node.put("y",          d._y);
            node.put("heading",    2);
            node.put("propertyId", d._propertyId);
            node.put("pngid",      d._pngId);
            node.put("blocking",   d._blocking);
            node.put("footprintW", d._footprintW);
            node.put("footprintH", d._footprintH);
            node.put("offsetX",    d._offsetX);
            node.put("offsetY",    d._offsetY);
            node.put("action",     false);
            node.put("actionType", 0);
            node.put("value",      0);
            arr.add(node);
        }
        putArray("properties", arr);
    }

    /** 建立玩家裝飾的推送封包（單筆＝新放置一件）。 */
    public static S_PropertyPack ofDecorations(int mapId, List<DecorationInstance> decorations) {
        return new S_PropertyPack(mapId, decorations);
    }

    /**
     * 建立指定地圖的 {@link S_PropertyPack} 封包。
     *
     * @param mapId 地圖編號
     */
    public static S_PropertyPack of(int mapId) {
        return new S_PropertyPack(mapId);
    }
}
