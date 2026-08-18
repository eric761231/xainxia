package com.xin.server.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.IdFactoryNpc;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.world.World;

/**
 * NPC 召喚工具（對齊天堂 L1SpawnUtil）。
 */
public final class SpawnUtil {

    private static final Logger _log = LoggerFactory.getLogger(SpawnUtil.class);

    private SpawnUtil() {
    }

    /**
     * 在指定座標召喚 NPC。
     *
     * @param npcId  NPC 模板編號
     * @param name   顯示名稱
     * @param x      座標 X
     * @param y      座標 Y
     * @param mapId  地圖編號
     */
    public static NpcInstance spawn(int npcId, String name, int x, int y, int mapId) {
        try {
            NpcInstance npc = new NpcInstance();
            npc.setId(IdFactoryNpc.get().nextId());
            npc.setNpcTemplateId(npcId);
            npc.setName(name);
            npc.setX(x);
            npc.setY(y);
            npc.setMapId(mapId);
            World.get().storeObject(npc);
            return npc;
        } catch (Exception e) {
            _log.error(e.getMessage(), e);
            return null;
        }
    }
}
