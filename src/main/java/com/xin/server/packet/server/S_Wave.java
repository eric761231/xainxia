package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 波次狀態（對應 opcode {@code S_WAVE}）。
 * <p>
 * 每秒廣播一次。內容很小（三個整數），與其設計「只在變化時送」的機制，
 * 不如固定頻率推送 —— 前端不必自己推算倒數，中途進來的玩家也立刻同步。
 *
 * <pre>
 * {
 *   "op": "S_WAVE",
 *   "data": { "wave": 3, "alive": 5, "breakLeft": 0 }
 * }
 * </pre>
 *
 * {@code breakLeft} > 0 代表這一波已清完，正在倒數下一波。
 */
public class S_Wave extends ServerBasePacket {

    private S_Wave(int wave, int alive, int breakLeft) {
        super(ServerOpcodes.S_WAVE);
        put("wave", wave);
        put("alive", alive);
        put("breakLeft", breakLeft);
    }

    public static S_Wave of(int wave, int alive, int breakLeft) {
        return new S_Wave(wave, alive, breakLeft);
    }
}
