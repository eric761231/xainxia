package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 挑戰結算（對應 opcode {@code S_GAME_OVER}）。
 * <p>
 * 玩家在秘境中死亡時送出，同時角色已被送回洞府。前端據此顯示結算畫面。
 * <p>
 * 這是死亡的<b>唯一出口</b>：在此之前玩家死了只能躺在原地
 * （不能攻擊、怪繼續打、只能重登）。
 *
 * <pre>
 * {
 *   "op": "S_GAME_OVER",
 *   "data": { "wave": 5, "kills": 23, "seconds": 142 }
 * }
 * </pre>
 */
public class S_GameOver extends ServerBasePacket {

    private S_GameOver(int wave, int kills, int seconds) {
        super(ServerOpcodes.S_GAME_OVER);
        put("wave", wave);
        put("kills", kills);
        put("seconds", seconds);
    }

    public static S_GameOver of(int wave, int kills, int seconds) {
        return new S_GameOver(wave, kills, seconds);
    }
}
