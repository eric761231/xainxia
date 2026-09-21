package com.xin.server.packet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

public abstract class ServerBasePacket {
	
	private static final ObjectMapper mapper = new ObjectMapper();

    private final ObjectNode root;
    private final ObjectNode data;

    public ServerBasePacket(String opcode) {
        this.root = mapper.createObjectNode();
        this.data = mapper.createObjectNode();
        root.put("op", opcode);
        root.set("data", data);
    }

    protected void put(String key, String value) {
        data.put(key, value);
    }

    protected void put(String key, int value) {
        data.put(key, value);
    }

    protected void put(String key, long value) {
        data.put(key, value);
    }

    protected void put(String key, boolean value) {
        data.put(key, value);
    }

    protected void putArray(String key, ArrayNode arr) {
        data.set(key, arr);
    }

    // 給子類別建立 ArrayNode 用
    /** 放一個巢狀物件（例如「編號 → 檔名」這種對照表）。 */
    protected void putObject(String key, ObjectNode obj) {
        data.set(key, obj);
    }

    protected ArrayNode newArray() {
        return mapper.createArrayNode();
    }

    // 給子類別建立 ObjectNode 用
    protected ObjectNode newObject() {
        return mapper.createObjectNode();
    }

    public String toJson() {
        try {
            return mapper.writeValueAsString(root) + "\n";
        } catch (Exception e) {
            throw new RuntimeException("封包序列化失敗", e);
        }
    }

    public String getOpcode() {
        return root.get("op").asText();
    }
}
