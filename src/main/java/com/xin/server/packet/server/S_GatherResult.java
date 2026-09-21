package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 採集結果（對應 opcode {@code S_GATHER_RESULT}）。
 * <p>
 * 回應 {@code C_GATHER}，**只送給採集者本人**，說明這次採集拿到什麼。
 * {@code success=false} 時以 {@code message} 說明原因（太遠／已枯竭／背包滿）。
 * <p>
 * 與 {@link S_PropertyUpdate} 的分工：本封包是給採集者的私人結果，
 * 而世界上該物件的狀態變化（進度、是否還能互動）由 {@code S_PROPERTY_UPDATE}
 * 廣播給全場；物件若直接消失則是 {@link S_ObjectRemove}。
 *
 * <pre>
 * {
 *   "op": "S_GATHER_RESULT",
 *   "data": {
 *     "success": true, "objId": 2000000003,
 *     "itemId": 40001, "itemName": "靈草", "amount": 1,
 *     "message": "", "respawnMs": 30000
 *   }
 * }
 * </pre>
 */
public class S_GatherResult extends ServerBasePacket {

    private S_GatherResult(boolean success, long objId, int itemId, String itemName,
                           int amount, String message, int respawnMs) {
        super(ServerOpcodes.S_GATHER_RESULT);
        put("success",   success);
        put("objId",     objId);
        put("itemId",    itemId);
        put("itemName",  itemName != null ? itemName : "");
        put("amount",    amount);
        put("message",   message != null ? message : "");
        put("respawnMs", respawnMs);
    }

    /**
     * 建立採集成功的結果封包。
     *
     * @param objId     被採集的場景物件編號
     * @param itemId    獲得的道具編號
     * @param itemName  獲得的道具名稱
     * @param amount    獲得數量
     * @param respawnMs 此節點的再生毫秒數（0=不再生）
     */
    public static S_GatherResult success(long objId, int itemId, String itemName,
                                         int amount, int respawnMs) {
        return new S_GatherResult(true, objId, itemId, itemName, amount, "", respawnMs);
    }

    /**
     * 建立採集失敗的結果封包。
     *
     * @param objId   目標場景物件編號
     * @param message 失敗原因（太遠／已枯竭／背包滿）
     */
    public static S_GatherResult fail(long objId, String message) {
        return new S_GatherResult(false, objId, 0, "", 0, message, 0);
    }
}
