package com.xin.server.packet.server;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

public class S_ServerList extends ServerBasePacket {

	public S_ServerList(String opcode) {
		super(opcode);
	}

	/** 建立一筆區服狀態並加入列表 */
    public Builder builder() {
        return new Builder();
    }
	
    public static final class Builder {
        private final S_ServerList packet = new S_ServerList(ServerOpcodes.S_SERVER_LIST);
        private final ArrayNode servers = packet.newArray();
        public Builder add(
                String id,
                int online,
                int max,
                String status
        ) {
            ObjectNode node = packet.newObject();
            node.put("id", id);
            node.put("online", online);
            node.put("max", max);
            node.put("status", status);
            servers.add(node);
            return this;
        }
        public S_ServerList build() {
            packet.putArray("servers", servers);
            return packet;
        }
    }
    /** 依人數比例計算 status（與前端 enum 對齊） */
    public static String calcStatus(int online, int max, boolean maintenance) {
        if (maintenance) {
            return "maintenance";
        }
        if (max <= 0) {
            return "offline";
        }
        if (online >= max) {
            return "full";
        }
        double ratio = (double) online / max;
        if (ratio >= 0.8) {
            return "crowded";
        }
        return "smooth";
    }
    
}
