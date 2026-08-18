package com.xin.server.packet.server;

import java.util.List;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.datatables.MapPortalTable;
import com.xin.server.datatables.MapTable;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.template.MapTemplate;
import com.xin.server.template.PortalTemplate;

/**
 * 地圖資訊（對應 opcode {@code S_MAP_INFO}）。
 * <p>
 * 進入遊戲或完成傳送後推送，前端根據此封包：
 * <ul>
 *   <li>顯示地圖名稱</li>
 *   <li>依 {@code width}/{@code height} 把傳送點格座標正規化，於小地圖以藍色光點標示</li>
 * </ul>
 *
 * <pre>
 * {
 *   "op": "S_MAP_INFO",
 *   "data": {
 *     "mapId": 1,
 *     "mapName": "青雲洞府",
 *     "width": 30,
 *     "height": 30,
 *     "portals": [
 *       { "portalId": 1, "locX": 17, "locY": 13, "triggerRange": 2, "name": "前往房屋外" },
 *       { "portalId": 4, "locX": 8,  "locY": 8,  "triggerRange": 0, "name": "前往梅花村" }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_MapInfo extends ServerBasePacket {

    private S_MapInfo(int mapId) {
        super(ServerOpcodes.S_MAP_INFO);
        put("mapId", mapId);
        put("mapName", MapTable.get().getName(mapId));

        // 地圖尺寸（格數）：供前端小地圖把傳送點格座標正規化到圓形範圍
        MapTemplate map = MapTable.get().getMap(mapId);
        put("width",  map != null ? map._maxX - map._minX + 1 : 0);
        put("height", map != null ? map._maxY - map._minY + 1 : 0);

        List<PortalTemplate> portals = MapPortalTable.get().getPortalsByMap(mapId);
        ArrayNode arr = newArray();
        for (PortalTemplate p : portals) {
            ObjectNode node = newObject();
            node.put("portalId",     p._portalId);
            node.put("locX",         p._locX);
            node.put("locY",         p._locY);
            node.put("triggerRange", p._triggerRange);
            node.put("name",         p._name);
            arr.add(node);
        }
        putArray("portals", arr);
    }

    /**
     * 建立指定地圖的 {@link S_MapInfo} 封包。
     *
     * @param mapId 地圖編號
     */
    public static S_MapInfo of(int mapId) {
        return new S_MapInfo(mapId);
    }
}
