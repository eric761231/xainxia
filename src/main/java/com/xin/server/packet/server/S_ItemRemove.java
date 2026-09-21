package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 道具從背包消失（對應 opcode {@code S_ITEM_REMOVE}）。
 * <p>
 * 只在該筆<b>整個沒了</b>時送（用光、丟棄、賣掉）。數量減少但還有剩的情況
 * 走 {@link S_ItemUpdate}，前端據此決定是移除該格還是只改數字。
 */
public class S_ItemRemove extends ServerBasePacket {

    private S_ItemRemove(long objId) {
        super(ServerOpcodes.S_ITEM_REMOVE);
        put("objId", objId);
    }

    public static S_ItemRemove of(long objId) {
        return new S_ItemRemove(objId);
    }
}
