package com.xin.server.network;

import com.xin.server.packet.server.S_MonsterPack;
import com.xin.server.packet.server.S_MapTiles;
import com.xin.server.packet.server.S_NpcPack;
import com.xin.server.packet.server.S_PcPack;
import com.xin.server.packet.server.S_PropertyPack;
import java.util.List;
import com.xin.server.datatables.CharacterDecorationTable;
import com.xin.server.model.instance.DecorationInstance;
import com.xin.server.model.instance.PcInstance;
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
    /**
     * 推送某地圖的全部物件給單一客戶端（NPC／怪物／場景物件三包）。
     * <p>
     * 進圖與換圖後都必須送，否則客戶端畫面上不會有任何物件 ——
     * 這三包<b>不能</b>只靠客戶端主動請求 {@code C_OBJECT_LIST}，
     * 那等於把「畫面正確」寄託在客戶端記得要問。
     */
    public static void sendMapObjects(Client client, int mapId) {
        // 圖磚要在物件之前送：前端拿到它才知道地面長什麼樣，
        // 沒有圖磚檔的地圖回 null，不送即可（前端退回程式產生的地面）。
        S_MapTiles tiles = S_MapTiles.of(mapId);
        if (tiles != null) {
            client.sendPacket(tiles);
        }

        client.sendPacket(S_NpcPack.of(mapId));
        // 玩家名單：沒有這一包的話，別人要等到「移動」才會出現在畫面上
        client.sendPacket(S_PcPack.of(mapId));
        client.sendPacket(S_MonsterPack.of(mapId));
        client.sendPacket(S_PropertyPack.of(mapId));

        // 玩家自己的家具：從 DB 依角色載入，只送給擁有者
        if (client.hasActiveChar()) {
            PcInstance pc = client.getActiveChar();
            List<DecorationInstance> deco =
                    CharacterDecorationTable.get().load(pc.getName(), mapId);
            pc.setDecorations(deco);
            if (!deco.isEmpty()) {
                client.sendPacket(S_PropertyPack.ofDecorations(mapId, deco));
            }
        }
    }

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
    // 廣播給同一張地圖上的玩家
    // ─────────────────────────────────────────
    /**
     * 只送給人在 {@code mapId} 上的玩家。
     * <p>
     * 人物的移動、轉向、名單都<b>必須</b>用這個而不是 {@link #broadcastAll} ——
     * 全服廣播的話，別張地圖上的玩家也會收到某人的移動封包，前端就會在
     * 自己的地圖上長出一個根本不在這裡的鬼影。
     */
    public static void broadcastToMap(int mapId, ServerBasePacket packet) {
        for (Client client : ClientManager.getAll()) {
            if (client.hasActiveChar()
                    && client.getActiveChar().getMapId() == mapId) {
                client.sendPacket(packet);
            }
        }
    }

    /**
     * 把某張地圖的玩家名單重送給圖上的每個人。
     * <p>
     * 進圖、換圖、下線之後都要呼叫 —— 少呼叫一次的症狀是「他明明走了，
     * 畫面上還站著」或「他進來了，我卻看不到他」。
     */
    public static void broadcastPcPack(int mapId) {
        broadcastToMap(mapId, S_PcPack.of(mapId));
    }

    /**
     * 換圖後把<b>兩張</b>地圖的名單都重送。
     * <p>
     * 只送新地圖是最容易犯的錯：舊地圖上的人不會收到任何東西，
     * 那個離開的人就會永遠站在他們的畫面上。
     */
    public static void broadcastPcPackForMove(int fromMapId, int toMapId) {
        broadcastPcPack(toMapId);
        if (fromMapId != toMapId) {
            broadcastPcPack(fromMapId);
        }
    }

    // ─────────────────────────────────────────
    // 廣播給視野內的玩家（之後地圖視野用）
    // ─────────────────────────────────────────
    public static void broadcastToVisible(Client sender, ServerBasePacket packet) {
        // 「視野」目前等於「同一張地圖」，還沒有距離裁切 —— 但已經不是全服廣播了：
        // 全服送的話，別張地圖的人會收到某人的移動，前端就會長出鬼影。
        if (!sender.hasActiveChar()) {
            return;
        }
        int mapId = sender.getActiveChar().getMapId();
        for (Client client : ClientManager.getAll()) {
            if (client.equals(sender) || !client.hasActiveChar()) {
                continue;
            }
            if (client.getActiveChar().getMapId() == mapId) {
                client.sendPacket(packet);
            }
        }
    }
	
}
