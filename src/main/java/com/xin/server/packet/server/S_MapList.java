package com.xin.server.packet.server;

import java.util.List;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.datatables.MapTable;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.template.MapTemplate;

/**
 * 地圖清單（對應 opcode {@code S_MAP_LIST}）。
 * <p>
 * 由 GM 指令 {@code .maps} 觸發，供 GM 面板畫出可傳送的地圖列表。
 * 刻意送<b>結構化資料</b>而非文字 —— 讓前端解析文字清單會很脆弱，
 * 地圖名稱一改就壞。
 *
 * <pre>
 * {
 *   "op": "S_MAP_LIST",
 *   "data": { "maps": [ { "mapId": 0, "name": "修練洞府" }, ... ] }
 * }
 * </pre>
 */
public class S_MapList extends ServerBasePacket {

    private S_MapList() {
        super(ServerOpcodes.S_MAP_LIST);

        List<MapTemplate> maps = MapTable.get().getAll();
        ArrayNode arr = newArray();
        for (MapTemplate m : maps) {
            ObjectNode node = newObject();
            node.put("mapId", m._mapId);
            node.put("name", m._name);
            arr.add(node);
        }
        putArray("maps", arr);
    }

    /** 建立含全部地圖的清單封包。 */
    public static S_MapList of() {
        return new S_MapList();
    }
}
