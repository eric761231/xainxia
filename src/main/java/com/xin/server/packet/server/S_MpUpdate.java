package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 法力更新（對應 opcode {@code S_MP_UPDATE}）。
 * <p>
 * 與 {@link S_HpUpdate} 同形，但推送對象不同：
 * 血條是所有看得見的人都要更新，法力則只送給**自己與隊友**
 * —— 敵對目標不該知道你還剩多少魔。
 * <p>
 * 施法扣魔、喝藥回魔、自然回復、升級補滿皆走本封包。
 *
 * <pre>
 * {
 *   "op": "S_MP_UPDATE",
 *   "data": { "objId": 1000000005, "currentMp": 22, "maxMp": 80 }
 * }
 * </pre>
 */
public class S_MpUpdate extends ServerBasePacket {

    private S_MpUpdate(long objId, int currentMp, int maxMp) {
        super(ServerOpcodes.S_MP_UPDATE);
        put("objId",     objId);
        put("currentMp", currentMp);
        put("maxMp",     maxMp);
    }

    /**
     * 建立法力更新封包。
     *
     * @param objId     法力變動的物件編號
     * @param currentMp 變動後的當前法力
     * @param maxMp     法力上限
     */
    public static S_MpUpdate of(long objId, int currentMp, int maxMp) {
        return new S_MpUpdate(objId, currentMp, maxMp);
    }
}
