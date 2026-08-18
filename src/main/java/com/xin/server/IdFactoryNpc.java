package com.xin.server;

import java.util.concurrent.atomic.AtomicLong;

/**
 * NPC OBJID 分配器（對齊天堂 IdFactoryNpc）。
 * <p>
 * 地圖 NPC、怪物、特效等執行期物件；不寫 DB，重啟後重新分配。
 */
public class IdFactoryNpc {

    /** 天堂 0x77359400 */
    private static final long NPC_ID_BASE = 2_000_000_000L;

    private static IdFactoryNpc _instance;

    private final Object _monitor = new Object();
    private final AtomicLong _nextId = new AtomicLong(NPC_ID_BASE);

    public static IdFactoryNpc get() {
        if (_instance == null) {
            _instance = new IdFactoryNpc();
        }
        return _instance;
    }

    /** 以原子方式將目前值加 1 並回傳。 */
    public long nextId() {
        synchronized (_monitor) {
            return _nextId.getAndIncrement();
        }
    }

    public long maxId() {
        synchronized (_monitor) {
            return _nextId.get();
        }
    }
}
