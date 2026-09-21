package com.xin.server.model.ai;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.NpcInstance;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_NpcMove;
import com.xin.server.world.MapGrid;
import com.xin.server.world.WorldMapGrid;

/**
 * NPC 的位置變動：更新座標、面向、生物占位，並通知同圖玩家。
 * 呼叫端必須持有該地圖的鎖。
 */
public final class NpcMove {

    private static final Logger _log = LoggerFactory.getLogger(NpcMove.class);

    private NpcMove() {
    }

    /**
     * 走一格。
     * <p>
     * 一定只能是相鄰一格：前端遇到超過一格的位移會直接瞬移，
     * 違反這條在畫面上是「怪物突然閃現」，很難從畫面回推到這裡。
     */
    public static boolean step(NpcInstance npc, int nx, int ny) {
        int dx = nx - npc.getX();
        int dy = ny - npc.getY();
        if (Math.max(Math.abs(dx), Math.abs(dy)) != 1) {
            _log.error("NPC {}（{}）的移動不是一格：({},{}) → ({},{})",
                    npc.getId(), npc.getName(), npc.getX(), npc.getY(), nx, ny);
            return false;
        }
        MapGrid grid = WorldMapGrid.get().get(npc.getMapId());
        if (grid != null) {
            grid.moveMover(npc.getId(), npc.getX(), npc.getY(), nx, ny);
        }
        npc.setX(nx);
        npc.setY(ny);
        npc.setHeading(PathFinder.headingOf(dx, dy));
        PacketSender.broadcastToMap(npc.getMapId(), S_NpcMove.of(npc));
        return true;
    }

    /** 原地轉向（座標不變的 S_NPC_MOVE，前端只會轉身）。 */
    public static void face(NpcInstance npc, int heading) {
        if (heading < 0 || heading == npc.getHeading()) {
            return;
        }
        npc.setHeading(heading);
        PacketSender.broadcastToMap(npc.getMapId(), S_NpcMove.of(npc));
    }

    /** 轉向面對 (x,y)。 */
    public static void faceToward(NpcInstance npc, int x, int y) {
        face(npc, PathFinder.headingOf(x - npc.getX(), y - npc.getY()));
    }

    /** 瞬移（回家卡住時用）；前端遇到超過一格的位移會直接瞬移過去。 */
    public static void teleport(NpcInstance npc, int x, int y) {
        MapGrid grid = WorldMapGrid.get().get(npc.getMapId());
        if (grid != null) {
            grid.moveMover(npc.getId(), npc.getX(), npc.getY(), x, y);
        }
        npc.setX(x);
        npc.setY(y);
        PacketSender.broadcastToMap(npc.getMapId(), S_NpcMove.of(npc));
    }
}
