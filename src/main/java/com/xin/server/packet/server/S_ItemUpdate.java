package com.xin.server.packet.server;

import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.model.instance.ItemInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 單一道具的新增或變更（對應 opcode {@code S_ITEM_UPDATE}）。
 * <p>
 * 前端是 <b>upsert 語意</b>：objId 已存在就更新，沒有就新增。所以「撿到新道具」
 * 與「數量改變」共用同一個封包，不必分成兩種。
 * <p>
 * 欄位與 {@link S_Inventory} 的每一項完全相同 —— 前端只需要一條解析路徑。
 */
public class S_ItemUpdate extends ServerBasePacket {

    private S_ItemUpdate(ItemInstance it) {
        super(ServerOpcodes.S_ITEM_UPDATE);
        ObjectNode n = newObject();
        S_Inventory.fill(n, it);
        putObject("item", n);
    }

    public static S_ItemUpdate of(ItemInstance it) {
        return new S_ItemUpdate(it);
    }
}
