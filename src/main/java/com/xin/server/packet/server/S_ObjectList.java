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
 * 地圖物件清單（對應 opcode {@code S_OBJECT_LIST}）。
 * <p>
 * 進入遊戲、換圖完成或前端主動請求（{@code C_OBJECT_LIST}）時推送，
 * 內含該地圖上所有 NPC／怪物／採集點／場景物件。
 * <p>
 * {@code type} 見 {@link NpcType}：0=怪物(可攻擊)、1=NPC(可交談)、2=商店(可交談買賣)、
 * 3=採集物(植物／礦物)、4=場景物件(不可互動)。
 * {@code attackable}/{@code talkable}/{@code shop}/{@code gatherable} 是由 type 推導出的
 * 便利旗標，讓前端不必重複判斷分類規則。
 *
 * <pre>
 * {
 *   "op": "S_OBJECT_LIST",
 *   "data": {
 *     "mapId": 1,
 *     "objects": [
 *       { "objId": 100001, "npcId": 45000, "name": "野狼", "type": 0, "gfxid": 1,
 *         "x": 10, "y": 12, "heading": 2,
 *         "maxHp": 50, "currentHp": 50,
 *         "attackable": true, "talkable": false, "shop": false, "gatherable": false }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_ObjectList extends ServerBasePacket {

    private S_ObjectList(int mapId) {
        super(ServerOpcodes.S_OBJECT_LIST);
        put("mapId", mapId);

        List<NpcInstance> npcs = WorldNpc.get().getNpcsByMap(mapId);
        ArrayNode arr = newArray();
        for (NpcInstance npc : npcs) {
            int type = npc.getType();
            ObjectNode node = newObject();
            node.put("objId",      npc.getId());
            node.put("npcId",      npc.getNpcTemplateId());
            node.put("name",       npc.getName());
            node.put("type",       type);
            node.put("gfxid",      npc.getGfxid());
            node.put("x",          npc.getX());
            node.put("y",          npc.getY());
            node.put("heading",    npc.getHeading());
            node.put("maxHp",      npc.getMaxHp());
            node.put("currentHp",  npc.getCurrentHp());
            node.put("attackable", NpcType.isAttackable(type));
            node.put("talkable",   NpcType.isTalkable(type));
            node.put("shop",       NpcType.isShop(type));
            node.put("gatherable", NpcType.isGatherable(type));
            arr.add(node);
        }
        putArray("objects", arr);
    }

    /**
     * 建立指定地圖的 {@link S_ObjectList} 封包。
     *
     * @param mapId 地圖編號
     */
    public static S_ObjectList of(int mapId) {
        return new S_ObjectList(mapId);
    }
}
