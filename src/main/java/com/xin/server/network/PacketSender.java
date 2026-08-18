package com.xin.server.network;

import com.xin.server.packet.ServerBasePacket;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 封包輸出管理
 * @author Eric
 */
public class PacketSender {

	private static final Logger logger = LoggerFactory.getLogger(PacketSender.class);
	
	
    // ─────────────────────────────────────────
    // 廣播給所有人
    // ─────────────────────────────────────────
    public static void broadcastAll(ServerBasePacket packet) {
        logger.debug("廣播 → 所有人 {}", packet.getOpcode());

        for (Client client : ClientManager.getAll()) {
        	client.sendPacket(packet);
        }
    }

    // ─────────────────────────────────────────
    // 廣播給所有人，排除自己
    // ─────────────────────────────────────────
    public static void broadcastExclude(Client exclude, ServerBasePacket packet) {
        for (Client client : ClientManager.getAll()) {
            if (!client.equals(exclude)) {
            	client.sendPacket(packet);
            }
        }
    }

    // ─────────────────────────────────────────
    // 廣播給視野內的玩家（之後地圖視野用）
    // ─────────────────────────────────────────
    public static void broadcastToVisible(Client sender, ServerBasePacket packet) {
        // 目前先廣播全部，之後加入視野計算
        broadcastExclude(sender, packet);
    }
	
}
