package com.xin.server.packet.server;

import java.util.List;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.types.NpcType;
import com.xin.server.world.WorldNpc;

/**
 * 怪物物件封包（對應 opcode {@code S_MONSTER_PACK}）。
 * <p>
 * 只含 {@link NpcType#MONSTER} 分類的物件，因此額外帶血量欄位。
 *
 * <pre>
 * {
 *   "op": "S_MONSTER_PACK",
 *   "data": {
 *     "mapId": 1,
 *     "monsters": [
 *       { "objId": 2000000001, "name": "野狼", "x": 10, "y": 12, "heading": 2,
 *         "npcId": 45000, "gfxid": 1, "maxHp": 50, "currentHp": 50 }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_MonsterPack extends ServerBasePacket {

    private S_MonsterPack(int mapId, List<NpcInstance> npcs) {
        super(ServerOpcodes.S_MONSTER_PACK);
        put("mapId", mapId);

        ArrayNode arr = newArray();
        for (NpcInstance npc : npcs) {
            if (npc.getType() != NpcType.MONSTER) {
                continue;
            }
            ObjectNode node = newObject();
            node.put("objId",     npc.getId());
            node.put("name",      npc.getName());
            node.put("x",         npc.getX());
            node.put("y",         npc.getY());
            node.put("heading",   npc.getHeading());
            node.put("npcId",     npc.getNpcTemplateId());
            node.put("gfxid",     npc.getGfxid());
            node.put("maxHp",     npc.getMaxHp());
            node.put("currentHp", npc.getCurrentHp());
            arr.add(node);
        }
        putArray("monsters", arr);
    }

    /**
     * 建立指定地圖的 {@link S_MonsterPack} 封包。
     *
     * @param mapId 地圖編號
     */
    public static S_MonsterPack of(int mapId) {
        return new S_MonsterPack(mapId, WorldNpc.get().getNpcsByMap(mapId));
    }

    /**
     * 只含一隻怪物的封包（例如重生）。
     * <p>
     * 前端對這包是逐筆 upsert、從不刪除，所以一筆的封包就等於「新增這一隻」，
     * 不必為一隻怪重送整張圖。
     */
    public static S_MonsterPack ofOne(NpcInstance npc) {
        return new S_MonsterPack(npc.getMapId(), List.of(npc));
    }
}
