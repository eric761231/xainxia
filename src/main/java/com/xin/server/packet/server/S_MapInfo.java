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
import com.xin.server.world.MapGrid;
import com.xin.server.world.WorldMapGrid;

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
 *     "gfxid": 2004,
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
        // 場景底圖編號：對應前端 object_catalog.json 的物件 id（與 property.pngid 同一套編號）
        put("gfxid",  map != null ? map._gfxid : 0);
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

        // 地形碰撞搭進來一起送，省一次往返；格式與 S_MapCollision 相同
        ArrayNode blocked = newArray();
        MapGrid grid = WorldMapGrid.get().get(mapId);
        if (grid != null) {
            for (int[] c : grid.getTerrainBlockedCells()) {
                ArrayNode pair = newArray();
                pair.add(c[0]);
                pair.add(c[1]);
                blocked.add(pair);
            }
        }
        putArray("blocked", blocked);
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
