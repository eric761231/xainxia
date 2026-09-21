package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * GM 指令執行結果（對應 opcode {@code S_GM_RESULT}）。
 * <p>
 * 只回饋給下指令的人，讓他知道指令有沒有生效、為什麼失敗。
 * 沒有這包的話，指令打錯字會完全沒有反應，很難分辨是「指令錯」還是「功能壞了」。
 *
 * <pre>
 * {
 *   "op": "S_GM_RESULT",
 *   "data": { "success": true, "message": "已傳送至 黑森林 (40,40)" }
 * }
 * </pre>
 */
public class S_GmResult extends ServerBasePacket {

    private S_GmResult(boolean success, String message) {
        super(ServerOpcodes.S_GM_RESULT);
        put("success", success);
        put("message", message != null ? message : "");
    }

    public static S_GmResult ok(String message) {
        return new S_GmResult(true, message);
    }

    public static S_GmResult fail(String message) {
        return new S_GmResult(false, message);
    }
}
