package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_MapInfo;

/**
 * 請求地圖資訊（小地圖：地名 + 傳送點清單）。
 * <p>
 * 客戶端 JSON 格式：
 * <pre>
 * { "op": "C_MAP_INFO", "data": {} }
 * </pre>
 *
 * 伺服器依角色當前 mapId 回傳 {@link S_MapInfo}。
 * 通常用於前端重新整理小地圖（如重新連線後同步）。
 */
public class C_MapInfo extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_MapInfo.class);

    public C_MapInfo(String raw) {
        super(raw);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_MAP_INFO 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();
        client.sendPacket(S_MapInfo.of(pc.getMapId()));
    }
}
