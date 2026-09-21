package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.MapCollisionTable;
import com.xin.server.gm.GmCommandHandler;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.packet.server.S_MapCollision;
import com.xin.server.world.MapGrid;
import com.xin.server.world.WorldMapGrid;

/**
 * GM 編輯地形碰撞：把單一格子標記為可走／不可走。
 * JSON: { "op": "C_GM_COLLISION", "data": { "x": 40, "y": 41, "blocked": true } }
 * <p>
 * 地形是<b>全體共用</b>的（不像家具只屬於擁有者），所以改完要廣播給所有人，
 * 而不是只回給下指令的 GM。
 */
public class C_GmCollision extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_GmCollision.class);

    private final int x;
    private final int y;
    private final boolean blocked;

    public C_GmCollision(String raw) {
        super(raw);
        x = getInt("x", 0);
        y = getInt("y", 0);
        blocked = getBool("blocked", true);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_GM_COLLISION 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        int level = client.getAccount() != null ? client.getAccount().getAccessLevel() : 0;
        if (level < GmCommandHandler.REQUIRED_ACCESS_LEVEL) {
            logger.warn("碰撞編輯遭拒（權限不足 {}）：char={}", level, pc.getName());
            return;
        }

        int mapId = pc.getMapId();
        MapGrid grid = WorldMapGrid.get().get(mapId);
        if (grid == null) {
            client.sendPacket(S_Chat.system("地圖不存在：" + mapId));
            return;
        }
        if (!grid.inBounds(x, y)) {
            client.sendPacket(S_Chat.system("座標超出地圖範圍"));
            return;
        }
        // 擋住角色腳下那格會讓他再也走不出來
        if (blocked && x == pc.getX() && y == pc.getY()) {
            client.sendPacket(S_Chat.system("不能擋住自己站的位置"));
            return;
        }

        boolean ok = blocked
                ? MapCollisionTable.get().insert(mapId, x, y)
                : MapCollisionTable.get().delete(mapId, x, y);
        if (!ok && blocked) {
            client.sendPacket(S_Chat.system("寫入失敗（資料庫錯誤）"));
            return;
        }
        grid.setTerrainBlocked(x, y, blocked);

        PacketSender.broadcastAll(new S_MapCollision(mapId));
        logger.info("GM碰撞編輯 char={} map={} ({},{}) → {}",
                pc.getName(), mapId, x, y, blocked ? "擋住" : "放行");
    }
}
