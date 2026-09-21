package com.xin.server.packet.server;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.model.Party;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 隊伍狀態（對應 opcode {@code S_PARTY}）。
 * <p>
 * 任何變動都<b>整包重送</b>給全隊。隊伍最多 5 人，整包重送遠比設計增量封包單純，
 * 也不會出現「某個成員的畫面沒更新到」。
 * <p>
 * 空隊伍（members 為空）代表<b>已離隊或解散</b>，前端據此清空隊伍欄。
 *
 * <pre>
 * {
 *   "op": "S_PARTY",
 *   "data": {
 *     "partyId": 1,
 *     "leaderObjId": 10002,
 *     "members": [
 *       { "objId": 10002, "name": "月蒼海", "level": 12,
 *         "hp": 160, "hpMax": 200, "mp": 30, "mpMax": 100 }
 *     ]
 *   }
 * }
 * </pre>
 */
public class S_Party extends ServerBasePacket {

    private S_Party(Party party) {
        super(ServerOpcodes.S_PARTY);
        put("partyId", party == null ? 0 : party.getId());
        put("leaderObjId",
                party == null || party.getLeader() == null ? 0
                        : party.getLeader().getId());

        ArrayNode arr = newArray();
        if (party != null) {
            for (PcInstance m : party.getMembers()) {
                ObjectNode n = newObject();
                n.put("objId", m.getId());
                n.put("name",  m.getName());
                n.put("level", m.getRealmLevel());
                n.put("hp",    m.getCurrentHp());
                n.put("hpMax", m.getMaxHp());
                n.put("mp",    m.getCurrentMp());
                n.put("mpMax", m.getMaxMp());
                arr.add(n);
            }
        }
        putArray("members", arr);
    }

    public static S_Party of(Party party) {
        return new S_Party(party);
    }

    /** 已離隊／解散：成員為空，前端據此清空隊伍欄。 */
    public static S_Party empty() {
        return new S_Party(null);
    }
}
