package com.xin.server.packet;


import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.xin.server.network.Client;

/**
 * 
 */
public abstract class ClientBasePacket {
	private static final ObjectMapper mapper = new ObjectMapper();

    protected final JsonNode data;
    private final String opcode;

    public ClientBasePacket(String raw) {
        try {
            JsonNode root = mapper.readTree(raw);
            this.opcode   = root.get("op").asText();
            this.data     = root.has("data")
                          ? root.get("data")
                          : mapper.createObjectNode();
        } catch (Exception e) {
            throw new RuntimeException("封包解析失敗：" + raw, e);
        }
    }
    
    protected String getString(String key, String def) {
        return data.has(key) ? data.get(key).asText() : def;
    }

    protected int getInt(String key, int def) {
        return data.has(key) ? data.get(key).asInt() : def;
    }

    protected long getLong(String key, long def) {
        return data.has(key) ? data.get(key).asLong() : def;
    }

    protected boolean getBool(String key, boolean def) {
        return data.has(key) ? data.get(key).asBoolean() : def;
    }

    public abstract void run(Client client);

    public String getOpcode() {
        return opcode;
    }
}
