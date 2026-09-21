package com.xin.server.packet.server;

import com.xin.server.model.Object;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 通用物件移除（對應 opcode {@code S_OBJECT_REMOVE}）。
 * <p>
 * 任何世界物件從地圖上消失時推送，前端依 {@code objId} 移除畫面上的對應物件：
 * <ul>
 *   <li>場景物件：藥草被採光、礦石被挖盡</li>
 *   <li>怪物：死亡</li>
 *   <li>NPC：下線／被 GM 移除</li>
 * </ul>
 * 因為前端只需要「哪個 objId 不見了」，不分物件類型共用同一包即可。
 *
 * <pre>
 * {
 *   "op": "S_OBJECT_REMOVE",
 *   "data": { "objId": 2000000003 }
 * }
 * </pre>
 */
public class S_ObjectRemove extends ServerBasePacket {

    private S_ObjectRemove(long objId) {
        super(ServerOpcodes.S_OBJECT_REMOVE);
        put("objId", objId);
    }

    /**
     * 建立物件移除封包。
     *
     * @param objId 消失的物件編號
     */
    public static S_ObjectRemove of(long objId) {
        return new S_ObjectRemove(objId);
    }

    /** 依世界物件建立移除封包。 */
    public static S_ObjectRemove of(Object obj) {
        return new S_ObjectRemove(obj.getId());
    }
}
