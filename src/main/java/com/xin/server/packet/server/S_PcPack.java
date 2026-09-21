package com.xin.server.packet.server;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.ClientManager;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 某張地圖上的其他玩家（對應 opcode {@code S_PC_PACK}）。
 * <p>
 * <b>整包重送，不做增量。</b>只要地圖上的人變動（進圖、換圖、下線）就把
 * 該圖的完整名單重送給圖上的每個人。同圖人數是個位數，封包很小，而這樣
 * 可以整類消滅「新增與移除對不上、畫面留下鬼影」的問題 —— 與
 * {@code PartyManager} 對隊伍的處理是同一個取捨。
 * <p>
 * 名單<b>包含收件者自己</b>由前端負責濾掉：伺服器對每張地圖只算一次名單，
 * 而不是為每個人各做一份少了自己的版本。
 *
 * <pre>
 * {
 *   "op": "S_PC_PACK",
 *   "data": {
 *     "mapId": 1,
 *     "players": [
 *       { "objId": 10099, "name": "洛清塵", "x": 40, "y": 40, "heading": 2,
 *         "sex": 0, "level": 3 }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_PcPack extends ServerBasePacket {

    private S_PcPack(int mapId) {
        super(ServerOpcodes.S_PC_PACK);
        put("mapId", mapId);

        ArrayNode arr = newArray();
        for (Client c : ClientManager.getAll()) {
            if (!c.hasActiveChar()) {
                continue;
            }
            PcInstance pc = c.getActiveChar();
            if (pc.getMapId() != mapId) {
                continue;
            }
            ObjectNode node = newObject();
            node.put("objId",   pc.getId());
            node.put("name",    pc.getName());
            node.put("x",       pc.getX());
            node.put("y",       pc.getY());
            node.put("heading", pc.getHeading());
            // 外觀目前只由性別決定（前端的 appearanceKey）
            node.put("sex",     pc.getSex());
            node.put("level",   pc.getRealmLevel());
            arr.add(node);
        }
        putArray("players", arr);
    }

    public static S_PcPack of(int mapId) {
        return new S_PcPack(mapId);
    }
}
