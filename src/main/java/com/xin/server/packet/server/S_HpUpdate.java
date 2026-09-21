package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 血量更新（對應 opcode {@code S_HP_UPDATE}）。
 * <p>
 * 任何物件的血量變動都走這一包，前端依 {@code objId} 更新血條：
 * 被攻擊扣血、使用道具／法術補血、升級補滿、自然回復、怪物初次現身皆適用。
 * <p>
 * 組隊時隊友的血條同樣靠這一包刷新 —— 因為以 {@code objId} 指定對象，
 * 自己、隊友、怪物共用同一套更新機制，前端不必分開處理。
 * <p>
 * 刻意與 {@link S_Attack} 分離：攻擊只負責「演出與傷害數字」，
 * 血量是獨立的狀態，會因為非攻擊原因（回血、buff）而改變。
 * 物件死亡不靠本封包表達，改送 {@link S_ObjectRemove}。
 * 法力另見 {@link S_MpUpdate}。
 *
 * <pre>
 * {
 *   "op": "S_HP_UPDATE",
 *   "data": { "objId": 2000000007, "currentHp": 13, "maxHp": 50 }
 * }
 * </pre>
 */
public class S_HpUpdate extends ServerBasePacket {

    private S_HpUpdate(long objId, int currentHp, int maxHp) {
        super(ServerOpcodes.S_HP_UPDATE);
        put("objId",     objId);
        put("currentHp", currentHp);
        put("maxHp",     maxHp);
    }

    /**
     * 建立血量更新封包。
     *
     * @param objId     血量變動的物件編號
     * @param currentHp 變動後的當前血量
     * @param maxHp     血量上限
     */
    public static S_HpUpdate of(long objId, int currentHp, int maxHp) {
        return new S_HpUpdate(objId, currentHp, maxHp);
    }
}
