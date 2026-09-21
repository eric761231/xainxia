package com.xin.server.packet.server;

import java.util.List;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.datatables.PropertyTable;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.template.PropertyTemplate;

/**
 * 可放置家具清單（對應 opcode {@code S_PLACEABLE_LIST}）。
 * <p>
 * 洞府布置面板用來顯示玩家能擺哪些東西。只列出 {@code property.placeable = 1} 的項目
 * —— 樹木、礦石那類世界物件不會出現在玩家的布置清單裡。
 * <p>
 * {@code placement} 決定該物件能放在什麼格子上（見 {@code PlacementSurface}），
 * 前端據此決定預覽時哪些格子是合法的。
 *
 * <pre>
 * {
 *   "op": "S_PLACEABLE_LIST",
 *   "data": {
 *     "items": [
 *       { "propertyId": 1200, "pngid": 1200, "name": "木桌一",
 *         "placement": "floor", "blocking": true,
 *         "footprintW": 1, "footprintH": 1 }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_PlaceableList extends ServerBasePacket {

    private S_PlaceableList() {
        super(ServerOpcodes.S_PLACEABLE_LIST);

        List<PropertyTemplate> items = PropertyTable.get().getPlaceable();
        ArrayNode arr = newArray();
        for (PropertyTemplate t : items) {
            ObjectNode node = newObject();
            node.put("propertyId", t._id);
            node.put("pngid",      t._pngId);
            node.put("name",       t._viewNote);
            node.put("placement",  t._placement != null ? t._placement : "floor");
            node.put("blocking",   t._blocking);
            node.put("footprintW", Math.max(1, t._footprintW));
            node.put("footprintH", Math.max(1, t._footprintH));
            arr.add(node);
        }
        putArray("items", arr);
    }

    public static S_PlaceableList of() {
        return new S_PlaceableList();
    }
}
