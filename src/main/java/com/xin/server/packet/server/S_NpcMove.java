package com.xin.server.packet.server;

import com.xin.server.model.instance.NpcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * NPC／怪物移動廣播（對應 opcode {@code S_NPC_MOVE}）。
 * <p>
 * 對應人物的 {@link S_CharMove}；差別在於人物以 {@code charName} 識別，
 * 而 NPC／怪物一律以 {@code objId} 識別（名稱會重複，例如同一張圖上多隻野狼）。
 * <p>
 * 怪物與 NPC 在伺服器同為 {@link NpcInstance}、移動欄位完全相同，因此共用本封包；
 * 前端可用 {@code objId} 直接對上 {@code S_NPC_PACK} 或 {@code S_MONSTER_PACK} 收到的物件。
 *
 * <pre>
 * {
 *   "op": "S_NPC_MOVE",
 *   "data": { "objId": 2000000001, "x": 11, "y": 12, "heading": 2 }
 * }
 * </pre>
 */
public class S_NpcMove extends ServerBasePacket {

    private S_NpcMove(long objId, int x, int y, int heading) {
        super(ServerOpcodes.S_NPC_MOVE);
        put("objId", objId);
        put("x", x);
        put("y", y);
        put("heading", heading);
    }

    /**
     * 建立移動廣播封包。
     *
     * @param objId   移動的 NPC／怪物物件編號
     * @param x       目的 X 座標
     * @param y       目的 Y 座標
     * @param heading 面向
     */
    public static S_NpcMove of(long objId, int x, int y, int heading) {
        return new S_NpcMove(objId, x, y, heading);
    }

    /** 依實例當前座標與面向建立移動廣播封包。 */
    public static S_NpcMove of(NpcInstance npc) {
        return new S_NpcMove(npc.getId(), npc.getX(), npc.getY(), npc.getHeading());
    }
}
