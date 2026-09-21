package com.xin.server.gm;

import java.util.List;

import com.xin.server.datatables.MapCollisionTable;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_MapCollision;
import com.xin.server.world.MapGrid;
import com.xin.server.world.WorldMapGrid;

/**
 * {@code .collision} —— 地形碰撞的文字介面。
 * <p>
 * 主要操作在 GM 面板的碰撞編輯模式（{@code C_GM_COLLISION}），
 * 本指令是備援與除錯管道：查目前有幾格、直接指定座標、以及清空整張地圖。
 */
public class GmCollision implements GmCommand {

    @Override
    public String name() {
        return "collision";
    }

    @Override
    public String usage() {
        return ".collision list | .collision <x> <y> on|off | .collision clear";
    }

    @Override
    public String description() {
        return "檢視／編輯目前地圖的地形碰撞格";
    }

    @Override
    public String execute(Client client, PcInstance pc, String[] args) {
        int mapId = pc.getMapId();
        MapGrid grid = WorldMapGrid.get().get(mapId);
        if (grid == null) {
            return "地圖不存在：" + mapId;
        }
        if (args.length == 0) {
            return usage();
        }

        String sub = args[0].toLowerCase();

        if ("list".equals(sub)) {
            List<int[]> cells = grid.getTerrainBlockedCells();
            if (cells.isEmpty()) {
                return "地圖 " + mapId + " 沒有任何地形碰撞格";
            }
            StringBuilder sb = new StringBuilder();
            sb.append("地圖 ").append(mapId).append(" 共 ")
              .append(cells.size()).append(" 格：");
            // 只列前 20 格，避免把聊天視窗灌爆
            int shown = Math.min(cells.size(), 20);
            for (int i = 0; i < shown; i++) {
                sb.append(" (").append(cells.get(i)[0]).append(',')
                  .append(cells.get(i)[1]).append(')');
            }
            if (cells.size() > shown) {
                sb.append(" …等");
            }
            return sb.toString();
        }

        if ("clear".equals(sub)) {
            List<int[]> cells = grid.getTerrainBlockedCells();
            for (int[] c : cells) {
                MapCollisionTable.get().delete(mapId, c[0], c[1]);
                grid.setTerrainBlocked(c[0], c[1], false);
            }
            PacketSender.broadcastAll(new S_MapCollision(mapId));
            return "已清空地圖 " + mapId + " 的 " + cells.size() + " 格地形碰撞";
        }

        if (args.length < 3) {
            return usage();
        }
        int x;
        int y;
        try {
            x = Integer.parseInt(args[0]);
            y = Integer.parseInt(args[1]);
        } catch (NumberFormatException e) {
            return "座標必須是數字。" + usage();
        }
        boolean blocked = !"off".equalsIgnoreCase(args[2]);

        if (!grid.inBounds(x, y)) {
            return "座標超出地圖範圍：(" + x + "," + y + ")";
        }
        if (blocked && x == pc.getX() && y == pc.getY()) {
            return "不能擋住自己站的位置";
        }

        if (blocked) {
            MapCollisionTable.get().insert(mapId, x, y);
        } else {
            MapCollisionTable.get().delete(mapId, x, y);
        }
        grid.setTerrainBlocked(x, y, blocked);
        PacketSender.broadcastAll(new S_MapCollision(mapId));
        return "(" + x + "," + y + ") 已設為" + (blocked ? "不可通行" : "可通行");
    }
}
