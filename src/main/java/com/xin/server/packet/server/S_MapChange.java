package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 換圖／傳送結果（對應 opcode {@code S_MAP_CHANGE}）。
 * <p>
 * 傳送點使用成功後發送，通知前端切換地圖並移動至目標座標。
 * 前端收到此封包後應清空當前地圖畫面並載入新地圖，
 * 隨後會收到 {@link S_MapInfo} 封包以更新小地圖上的傳送點光點。
 *
 * <pre>
 * {
 *   "op": "S_MAP_CHANGE",
 *   "data": {
 *     "mapId": 2,
 *     "x": 60,
 *     "y": 60
 *   }
 * }
 * </pre>
 */
public class S_MapChange extends ServerBasePacket {

    private S_MapChange(int mapId, int x, int y, int facing) {
        super(ServerOpcodes.S_MAP_CHANGE);
        put("mapId", mapId);
        put("x", x);
        put("y", y);
        put("facing", facing);
    }

    /**
     * 建立傳送結果封包。
     *
     * @param mapId  目標地圖編號
     * @param x      目標 X 座標（格）
     * @param y      目標 Y 座標（格）
     * @param facing 到達面向 0..7
     */
    public static S_MapChange of(int mapId, int x, int y, int facing) {
        return new S_MapChange(mapId, x, y, facing);
    }
}
