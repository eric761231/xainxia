package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_ObjectList;

/**
 * 請求地圖物件清單（NPC／怪物／採集點／場景物件）。
 * <p>
 * 客戶端 JSON 格式：
 * <pre>
 * { "op": "C_OBJECT_LIST", "data": {} }
 * </pre>
 *
 * 伺服器依角色當前 mapId 回傳 {@link S_ObjectList}。
 * 用於前端進圖後或重新連線後重建地圖物件。
 */
public class C_ObjectList extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_ObjectList.class);

    public C_ObjectList(String raw) {
        super(raw);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_OBJECT_LIST 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();
        client.sendPacket(S_ObjectList.of(pc.getMapId()));
    }
}
