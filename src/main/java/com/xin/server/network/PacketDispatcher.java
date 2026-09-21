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
import com.xin.server.packet.client.C_PlaceProperty;
import com.xin.server.packet.client.C_RemoveProperty;
import com.xin.server.packet.client.C_Attack;
import com.xin.server.packet.client.C_Challenge;
import com.xin.server.packet.client.C_Party;
import com.xin.server.packet.client.C_DropItem;
import com.xin.server.packet.client.C_GmCollision;
import com.xin.server.packet.client.C_UseItem;
import com.xin.server.packet.client.C_MoveProperty;
import com.xin.server.packet.client.C_PlaceableList;
import com.xin.server.packet.client.C_Chat;
import com.xin.server.packet.client.C_GmCommand;
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

            case ClientOpcodes.C_GM_COMMAND:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_GM_COMMAND");
                    return;
                }
                new C_GmCommand(raw).run(client);
                break;

            case ClientOpcodes.C_CHAT:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_CHAT");
                    return;
                }
                new C_Chat(raw).run(client);
                break;

            case ClientOpcodes.C_PLACE_PROPERTY:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_PLACE_PROPERTY");
                    return;
                }
                new C_PlaceProperty(raw).run(client);
                break;

            case ClientOpcodes.C_REMOVE_PROPERTY:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_REMOVE_PROPERTY");
                    return;
                }
                new C_RemoveProperty(raw).run(client);
                break;

            case ClientOpcodes.C_PLACEABLE_LIST:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_PLACEABLE_LIST");
                    return;
                }
                new C_PlaceableList(raw).run(client);
                break;

            case ClientOpcodes.C_MOVE_PROPERTY:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_MOVE_PROPERTY");
                    return;
                }
                new C_MoveProperty(raw).run(client);
                break;

            // 權限在 C_GmCollision.run() 內檢查（同 C_GM_COMMAND 的作法）
            case ClientOpcodes.C_CHALLENGE:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_CHALLENGE");
                    return;
                }
                new C_Challenge(raw).run(client);
                break;

            case ClientOpcodes.C_PARTY:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_PARTY");
                    return;
                }
                new C_Party(raw).run(client);
                break;

            case ClientOpcodes.C_ATTACK:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_ATTACK");
                    return;
                }
                new C_Attack(raw).run(client);
                break;

            case ClientOpcodes.C_USE_ITEM:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_USE_ITEM");
                    return;
                }
                new C_UseItem(raw).run(client);
                break;

            case ClientOpcodes.C_DROP_ITEM:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_DROP_ITEM");
                    return;
                }
                new C_DropItem(raw).run(client);
                break;

            case ClientOpcodes.C_GM_COLLISION:
                if (!client.hasActiveChar()) {
                    logger.warn("狀態錯誤，收到 C_GM_COLLISION");
                    return;
                }
                new C_GmCollision(raw).run(client);
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

