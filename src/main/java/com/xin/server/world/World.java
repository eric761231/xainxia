package com.xin.server.world;

import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.Object;
import com.xin.server.model.instance.ItemInstance;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.util.PerformanceTimer;

/**
 * 遊戲世界儲存中心（對齊天堂 World）。
 */
public class World {

    private static final Logger _log = LoggerFactory.getLogger(World.class);

    private static World _instance;

    /** 世界物件 &lt;ObjId, Object&gt; */
    private final ConcurrentHashMap<Long, Object> _allObjects = new ConcurrentHashMap<>();
    /** 世界玩家 &lt;角色名, PcInstance&gt; */
    private final ConcurrentHashMap<String, PcInstance> _allPlayers = new ConcurrentHashMap<>();

    private World() {
        final PerformanceTimer timer = new PerformanceTimer();
        _log.info("遊戲世界儲存中心建立完成 ({}ms)", timer.get());
    }

    public static World get() {
        if (_instance == null) {
            _instance = new World();
        }
        return _instance;
    }

    /** 加入世界 */
    public void storeObject(Object object) {
        if (object == null) {
            return;
        }
        _allObjects.put(object.getId(), object);
        if (object instanceof PcInstance pc) {
            _allPlayers.put(pc.getName(), pc);
        }
        if (object instanceof NpcInstance npc) {
            WorldNpc.get().put(npc.getId(), npc);
        }
        if (object instanceof ItemInstance item) {
            WorldItem.get().put(item.getId(), item);
        }
    }

    /** 移出世界 */
    public void removeObject(Object object) {
        if (object == null) {
            return;
        }
        _allObjects.remove(object.getId());
        if (object instanceof PcInstance pc) {
            _allPlayers.remove(pc.getName());
        }
        if (object instanceof NpcInstance npc) {
            WorldNpc.get().remove(npc.getId());
        }
        if (object instanceof ItemInstance item) {
            WorldItem.get().remove(item.getId());
        }
    }

    public Object findObject(long objId) {
        return _allObjects.get(objId);
    }

    public PcInstance findPc(String name) {
        return _allPlayers.get(name);
    }
}
