package com.xin.server.network;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.xin.server.packet.ClientOpcodes;
import com.xin.server.packet.client.C_AuthLogin;
import com.xin.server.packet.client.C_AuthLogout;
import com.xin.server.packet.client.C_Breakthrough;
import com.xin.server.packet.client.C_EnterPortal;
import com.xin.server.packet.client.C_Face;
import com.xin.server.packet.client.C_GainExp;
import com.xin.server.packet.client.C_MapInfo;
import com.xin.server.packet.client.C_Move;
import com.xin.server.packet.client.C_ObjectList;
import com.xin.server.packet.client.C_CharList;
import com.xin.server.packet.client.C_CreateCharacter;
import com.xin.server.packet.client.C_DeleteCharacter;
import com.xin.server.packet.client.C_SelectCharacter;
import com.xin.server.packet.client.C_ServerList;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 客戶端封包派發管理
 * @author Eric
 */

public class PacketDispatcher {

	private static final Logger logger = LoggerFactory.getLogger(PacketDispatcher.class);
	private static final ObjectMapper mapper = new ObjectMapper();
	// ─────────────────────────────────────────
	// 封包分發
	// ─────────────────────────────────────────
	public static void dispatch(Client client, String raw) {
	    try {
	        JsonNode root = mapper.readTree(raw);
	        if (!root.has("op")) {
	            logger.warn("封包缺少 op 欄位：{}", raw);
	            return;
	        }
	        String op = root.get("op").asText();
	        logger.debug("C包 ← [{}] {}", client.getChannel().remoteAddress(), op);
	        switch (op) {
	            case ClientOpcodes.C_AUTH_LOGIN:
	                if (!client.isConnected()) {
	                    logger.warn("狀態錯誤，收到 C_AUTH_LOGIN");
	                    return;
	                }
	                new C_AuthLogin(raw).run(client);
	                break;
	            case ClientOpcodes.C_AUTH_LOGOUT:
	                if (!client.isAuthenticated()) {
	                    logger.warn("狀態錯誤，收到 C_AUTH_LOGOUT");
	                    return;
	                }
	                new C_AuthLogout(raw).run(client);
	                break;
	            case ClientOpcodes.C_CHAR_LIST:
	                if (!client.isAuthenticated()) {
	                    logger.warn("狀態錯誤，收到 C_CHAR_LIST");
	                    return;
	                }
	                new C_CharList(raw).run(client);
	                break;
	            case ClientOpcodes.C_CREATE_CHAR:
	                if (!client.isAuthenticated()) {
	                    logger.warn("狀態錯誤，收到 C_CREATE_CHAR");
	                    return;
	                }
	                new C_CreateCharacter(raw).run(client);
	                break;
	            case ClientOpcodes.C_DELETE_CHAR:
                if (!client.isAuthenticated()) {
                    logger.warn("狀態錯誤，收到 C_DELETE_CHAR");
                    return;
                }
                new C_DeleteCharacter(raw).run(client);
                break;
            case ClientOpcodes.C_SELECT_CHAR:
	                if (!client.isAuthenticated()) {
	                    logger.warn("狀態錯誤，收到 C_SELECT_CHAR");
	                    return;
	                }
	                new C_SelectCharacter(raw).run(client);
	                break;
	            case ClientOpcodes.C_SERVER_LIST:
	                if (!client.isConnected()) {
	                    logger.warn("狀態錯誤，收到 C_SERVER_LIST");
	                    return;
	                }
	                new C_ServerList(raw).run(client);
	                break;
	            case ClientOpcodes.C_BREAKTHROUGH:
	                if (!client.hasActiveChar()) {
	                    logger.warn("狀態錯誤，收到 C_BREAKTHROUGH");
	                    return;
	                }
	                new C_Breakthrough(raw).run(client);
	                break;
	            case ClientOpcodes.C_GAIN_EXP:
	                if (!client.hasActiveChar()) {
	                    logger.warn("狀態錯誤，收到 C_GAIN_EXP");
	                    return;
	                }
	                new C_GainExp(raw).run(client);
	                break;
	            case ClientOpcodes.C_MOVE:
	                if (!client.hasActiveChar()) {
	                    logger.warn("狀態錯誤，收到 C_MOVE");
	                    return;
	                }
	                new C_Move(raw).run(client);
	                break;
            case ClientOpcodes.C_FACE:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_FACE");
                    return;
                }
                new C_Face(raw).run(client);
                break;
            case ClientOpcodes.C_ENTER_PORTAL:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_ENTER_PORTAL");
                    return;
                }
                new C_EnterPortal(raw).run(client);
                break;
            case ClientOpcodes.C_MAP_INFO:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_MAP_INFO");
                    return;
                }
                new C_MapInfo(raw).run(client);
                break;
            case ClientOpcodes.C_OBJECT_LIST:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_OBJECT_LIST");
                    return;
                }
                new C_ObjectList(raw).run(client);
                break;
            default:
	                logger.warn("未知封包 opcode：{}", op);
	                break;
	        }
	    } catch (Exception e) {
	        logger.error("封包分發異常：{}", raw, e);
	    }
	}
}

