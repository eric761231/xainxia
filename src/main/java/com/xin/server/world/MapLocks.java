package com.xin.server.world;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Supplier;

/**
 * 每張地圖一把鎖，保護該圖上 NPC 的狀態與生物占位格。
 * <p>
 * NPC 的 AI 跑在 NPC 執行緒池，玩家攻擊跑在 Netty 封包執行緒，兩邊都會改同一隻怪
 * （血量、仇恨、位置）與同一張占位格。以地圖為單位上鎖：移動要讀別的 NPC 位置與格子，
 * 每隻 NPC 各一把鎖保護不到格子，還會產生鎖的先後順序問題。
 * <p>
 * <b>規則</b>（違反會造成死結或讓整張圖卡住）：
 * <ul>
 *   <li>不同時持有兩把地圖鎖。</li>
 *   <li>鎖內不做 DB 存取（寫經驗、存角色等交給 {@code ThreadPoolManager.general()}）。
 *       封包送出是 Netty 的非同步寫入，可以在鎖內做。</li>
 *   <li>鎖內只做快的事：格子查詢、欄位讀寫、組封包。</li>
 * </ul>
 */
public final class MapLocks {

    private static final ConcurrentHashMap<Integer, ReentrantLock> LOCKS = new ConcurrentHashMap<>();

    private MapLocks() {
    }

    public static ReentrantLock of(int mapId) {
        return LOCKS.computeIfAbsent(mapId, k -> new ReentrantLock());
    }

    public static void run(int mapId, Runnable body) {
        ReentrantLock lock = of(mapId);
        lock.lock();
        try {
            body.run();
        } finally {
            lock.unlock();
        }
    }

    public static <T> T call(int mapId, Supplier<T> body) {
        ReentrantLock lock = of(mapId);
        lock.lock();
        try {
            return body.get();
        } finally {
            lock.unlock();
        }
    }
}
