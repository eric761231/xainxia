package com.xin.server.packet.server;

import java.util.Map;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.datatables.MapTileTable;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.template.MapTileTemplate;

/**
 * 地圖圖磚（對應 opcode {@code S_MAP_TILES}）。
 * <p>
 * 進圖時送出，告訴前端<b>哪個座標鋪哪一張圖</b>。前端據此組出地面，
 * 不再自己持有地圖資料。
 * <p>
 * <b>前後端的統一代號是圖磚編號</b>，配合 {@code tiles} 對照表使用：
 * 編號本身沒有意義，要看它對到哪個檔名。這樣重新切圖、換掉某一張，
 * 只要改對照表，地圖資料一格都不用動。
 *
 * <pre>
 * {
 *   "op": "S_MAP_TILES",
 *   "data": {
 *     "mapId": 0,
 *     "tileWidth": 64, "tileHeight": 32,
 *     "walkMin": 31, "walkMax": 50,
 *     "tileDir": "ground",
 *     "tiles": { "1": "brick_light_1.png", "2": "brick_light_2.png", ... },
 *     "ground": [[31,31,7],[32,31,7], ...]     // [x, y, 圖磚編號]
 *   }
 * }
 * </pre>
 *
 * {@code ground} 的座標<b>就是遊戲格座標</b>，前端自己換算陣列索引 ——
 * 中間不再有 coordOffset 這種容易對錯的東西。沒列到的格子就是不鋪。
 */
public class S_MapTiles extends ServerBasePacket {

    private S_MapTiles(MapTileTemplate t) {
        super(ServerOpcodes.S_MAP_TILES);
        put("mapId", t._mapId);
        put("tileWidth", t._tileWidth);
        put("tileHeight", t._tileHeight);
        put("walkMin", t._walkMin);
        put("walkMax", t._walkMax);
        put("tileDir", t._tileDir);

        ObjectNode tiles = newObject();
        for (Map.Entry<Integer, String> e : t._tiles.entrySet()) {
            tiles.put(String.valueOf(e.getKey()), e.getValue());
        }
        putObject("tiles", tiles);

        ArrayNode ground = newArray();
        for (MapTileTemplate.Cell c : t._ground) {
            ArrayNode cell = newArray();
            cell.add(c._x);
            cell.add(c._y);
            cell.add(c._tileId);
            ground.add(cell);
        }
        putArray("ground", ground);
    }

    /**
     * 建立指定地圖的圖磚封包；該地圖沒有圖磚檔時回傳 {@code null}。
     * <p>
     * 回傳 null 是正常情形，呼叫端不送即可 —— 前端會退回程式產生的地面。
     */
    public static S_MapTiles of(int mapId) {
        MapTileTemplate t = MapTileTable.get().getMap(mapId);
        return t == null ? null : new S_MapTiles(t);
    }
}
