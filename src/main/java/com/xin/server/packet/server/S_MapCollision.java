package com.xin.server.packet.server;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.world.MapGrid;
import com.xin.server.world.WorldMapGrid;

/**
 * 地圖的地形碰撞格（對應 opcode {@code S_MAP_COLLISION}）。
 * <p>
 * GM 即時編輯後廣播；進圖時的初始狀態則搭在 {@link S_MapInfo} 的 {@code blocked} 欄位
 * 一起送，省一次往返。兩者的欄位格式刻意相同，前端只需一條解析路徑。
 * <p>
 * 20×20 的地圖最壞 400 組、約 3KB，且只在進圖與 GM 編輯時送，
 * 不值得為此設計位元壓縮格式 —— 保持可讀便於除錯。
 *
 * <pre>
 * {
 *   "op": "S_MAP_COLLISION",
 *   "data": {
 *     "mapId": 0,
 *     "blocked": [[40,41],[40,42]]
 *   }
 * }
 * </pre>
 */
public class S_MapCollision extends ServerBasePacket {

    public S_MapCollision(int mapId) {
        super(ServerOpcodes.S_MAP_COLLISION);
        put("mapId", mapId);

        ArrayNode arr = newArray();
        MapGrid grid = WorldMapGrid.get().get(mapId);
        if (grid != null) {
            for (int[] c : grid.getTerrainBlockedCells()) {
                ArrayNode pair = newArray();
                pair.add(c[0]);
                pair.add(c[1]);
                arr.add(pair);
            }
        }
        putArray("blocked", arr);
    }
}
