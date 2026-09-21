package com.xin.server.packet.server;

import com.xin.server.model.ChallengeManager;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 角色進入世界。
 * <p>
 * 除了角色自己的資料，也帶上前端需要的<b>伺服器常數</b>：目前只有
 * {@code challengeMapId}。前端要靠它決定快捷列顯示「秘境」還是「離開秘境」——
 * 兩邊各寫一個常數的話，企劃改了 {@code wave_config} 的地圖，
 * 前端的按鈕就會停在舊的那張圖上，而且不會有任何錯誤訊息。
 */
public class S_EnterGame extends ServerBasePacket {

    public S_EnterGame(long objId, String charName, int mapId, int x, int y) {
        super(ServerOpcodes.S_ENTER_GAME);
        put("objId", objId);
        put("charName", charName);
        put("mapId", mapId);
        put("x", x);
        put("y", y);
        put("challengeMapId", ChallengeManager.challengeMapId());
    }
}
