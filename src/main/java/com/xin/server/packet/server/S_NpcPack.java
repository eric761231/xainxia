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
 * NPC 物件封包（對應 opcode {@code S_NPC_PACK}）。
 * <p>
 * 含 {@link NpcType#MONSTER} 以外的所有 NPC 分類（NPC／商店／採集物／場景 NPC），
 * 怪物另由 {@link S_MonsterPack} 推送。不帶血量欄位。
 * {@code type} 見 {@link NpcType}：1=NPC(可交談)、2=商店、3=採集物、4=場景物件。
 *
 * <pre>
 * {
 *   "op": "S_NPC_PACK",
 *   "data": {
 *     "mapId": 1,
 *     "npcs": [
 *       { "objId": 2000000002, "name": "藥童", "x": 20, "y": 22, "heading": 2,
 *         "npcId": 46000, "gfxid": 7, "type": 1 }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_NpcPack extends ServerBasePacket {

    private S_NpcPack(int mapId) {
        super(ServerOpcodes.S_NPC_PACK);
        put("mapId", mapId);

        List<NpcInstance> npcs = WorldNpc.get().getNpcsByMap(mapId);
        ArrayNode arr = newArray();
        for (NpcInstance npc : npcs) {
            if (npc.getType() == NpcType.MONSTER) {
                continue;
            }
            ObjectNode node = newObject();
            node.put("objId",   npc.getId());
            node.put("name",    npc.getName());
            node.put("x",       npc.getX());
            node.put("y",       npc.getY());
            node.put("heading", npc.getHeading());
            node.put("npcId",   npc.getNpcTemplateId());
            node.put("gfxid",   npc.getGfxid());
            node.put("type",    npc.getType());
            arr.add(node);
        }
        putArray("npcs", arr);
    }

    /**
     * 建立指定地圖的 {@link S_NpcPack} 封包。
     *
     * @param mapId 地圖編號
     */
    public static S_NpcPack of(int mapId) {
        return new S_NpcPack(mapId);
    }
}
