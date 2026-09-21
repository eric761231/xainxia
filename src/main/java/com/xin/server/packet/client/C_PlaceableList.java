package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_PlaceableList;

/**
 * 請求可放置家具清單。
 * JSON: { "op": "C_PLACEABLE_LIST", "data": {} }
 * <p>
 * 洞府布置面板開啟時送出，伺服器回 {@link S_PlaceableList}。
 */
public class C_PlaceableList extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_PlaceableList.class);

    public C_PlaceableList(String raw) {
        super(raw);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_PLACEABLE_LIST 失敗：尚未進入遊戲");
            return;
        }
        client.sendPacket(S_PlaceableList.of());
    }
}
