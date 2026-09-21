package com.xin.server.gm;

import com.xin.server.datatables.MapTable;
import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_MapChange;
import com.xin.server.packet.server.S_MapInfo;
import com.xin.server.template.MapTemplate;

/**
 * {@code .tp <mapId> [x] [y]} —— 傳送到指定地圖。
 * <p>
 * 省略座標時落在該地圖的正中央。換圖流程與 {@code C_ENTER_PORTAL} 一致：
 * 更新角色位置 → 存檔 → 送 {@link S_MapChange} 讓前端重建世界 → 送 {@link S_MapInfo}
 * 補上新地圖的底圖編號與傳送點。
 */
public class GmTeleport implements GmCommand {

    @Override
    public String name() {
        return "tp";
    }

    @Override
    public String usage() {
        return ".tp <地圖編號> [x] [y]";
    }

    @Override
    public String description() {
        return "傳送到指定地圖（省略座標則到地圖中央）";
    }

    @Override
    public String execute(Client client, PcInstance pc, String[] args) {
        if (args.length < 1) {
            return "用法：" + usage();
        }

        final int mapId;
        try {
            mapId = Integer.parseInt(args[0]);
        } catch (NumberFormatException e) {
            return "地圖編號必須是數字：" + args[0];
        }

        MapTemplate map = MapTable.get().getMap(mapId);
        if (map == null) {
            return "地圖不存在：" + mapId;
        }

        // 未指定座標就取地圖正中央
        int x = (map._minX + map._maxX) / 2;
        int y = (map._minY + map._maxY) / 2;
        if (args.length >= 3) {
            try {
                x = Integer.parseInt(args[1]);
                y = Integer.parseInt(args[2]);
            } catch (NumberFormatException e) {
                return "座標必須是數字：" + args[1] + "," + args[2];
            }
        }

        if (!map.isValidCoord(x, y)) {
            return String.format("座標 (%d,%d) 超出 %s 的範圍 %d..%d",
                    x, y, map._name, map._minX, map._maxX);
        }

        int prevMap = pc.getMapId();
        pc.setMapId(mapId);
        pc.setX(x);
        pc.setY(y);
        CharacterR.get().storeCharacter(pc);

        client.sendPacket(S_MapChange.of(mapId, x, y, pc.getHeading()));
        client.sendPacket(S_MapInfo.of(mapId));
        PacketSender.sendMapObjects(client, mapId);
        PacketSender.broadcastPcPackForMove(prevMap, mapId);

        return String.format("已從地圖 %d 傳送至 %s(%d) (%d,%d)",
                prevMap, map._name, mapId, x, y);
    }
}
