package com.xin.server.model;

import java.util.concurrent.ThreadLocalRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.MonsterSpawnTable;
import com.xin.server.datatables.NpcTable;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_MonsterPack;
import com.xin.server.template.SpawnTemplate;
import com.xin.server.thread.ThreadPoolManager;
import com.xin.server.world.MapLocks;

/**
 * 怪物重生。
 * <p>
 * 沒有重生的話，第一批怪被清光之後地圖就永遠空了 —— 打怪這條迴圈只能跑一次。
 * <p>
 * 重生的是<b>一隻新的怪</b>（新的 objId），不是把屍體救活。前端已經收到
 * {@code S_OBJECT_REMOVE} 把原本那隻移除了，沿用舊 objId 會讓前端以為是
 * 「已經不存在的東西又動了起來」。
 * <p>
 * <b>重生在生成點，不在死亡地點。</b>在死亡地點重生的話，被玩家風箏過的怪會一代
 * 一代往外遷移，最後整個區域的怪都擠到玩家常站的地方。
 */
public final class MonsterSpawner {

    private static final Logger _log = LoggerFactory.getLogger(MonsterSpawner.class);

    /**
     * 生成點查不到時的重生延遲（秒）。
     * <p>
     * 只是後備值 —— 正常情況每一筆 spawnlist_monster 都有自己的 {@code respawn_delay}，
     * 妖魔與洞穴蝠不該用同一個數字回來。
     */
    private static final int DEFAULT_RESPAWN_SECONDS = 15;

    /**
     * 最短重生時間（毫秒）。
     * <p>
     * 前端的屍體要停留約 3.25 秒（死亡動畫 + 淡出 + 停留）。比這更快重生的話，
     * 新怪會疊在還在淡出的屍體上，看起來像詐屍。
     */
    private static final long MIN_RESPAWN_MS = 4000;

    private MonsterSpawner() {
    }

    /** 依剛死掉那隻所屬的生成點，排程一隻新的。 */
    public static void scheduleRespawn(NpcInstance dead) {
        final int spawnId = dead.getSpawnId();
        final SpawnTemplate spawn = MonsterSpawnTable.get().getSpawn(spawnId);

        if (spawn != null && spawn._respawnDelay <= 0) {
            // 0＝這個生成點不重生
            _log.debug("生成點 {} 設定為不重生，{} 不再生成", spawnId, dead.getName());
            return;
        }

        long delayMs = Math.max(MIN_RESPAWN_MS, delaySecondsOf(spawn) * 1000L);
        final String name = dead.getName();

        if (spawn == null) {
            // 不是由生成點生的（GM 召喚等）：沒有生成點可回，就在原地重生
            final int npcId = dead.getNpcTemplateId();
            final int mapId = dead.getMapId();
            final int x = dead.getX();
            final int y = dead.getY();
            ThreadPoolManager.get().npc().schedule("respawn:" + name, delayMs, () ->
                    MapLocks.run(mapId, () -> {
                        NpcInstance npc = NpcTable.get().createNpc(npcId, x, y, mapId);
                        if (npc != null) {
                            npc.setHome(mapId, x, y);
                            announce(npc);
                        }
                    }));
            return;
        }

        // 生成會寫入占位格並加入世界：在該地圖的鎖內做，與 AI、玩家攻擊互斥
        ThreadPoolManager.get().npc().schedule("respawn:" + name, delayMs, () -> MapLocks.run(spawn._mapId, () -> {
            NpcInstance npc = MonsterSpawnTable.get().spawnOne(spawn);
            if (npc == null) {
                // 生成點範圍內暫時沒有可站的位置（例如被擋住）：稍後再試，不要永久少一隻
                _log.warn("怪物重生失敗：生成點 {}（{}）暫無可站位置，{} 毫秒後重試",
                        spawn._id, spawn._name, MIN_RESPAWN_MS);
                ThreadPoolManager.get().npc().schedule("respawn-retry:" + name, MIN_RESPAWN_MS,
                        () -> MapLocks.run(spawn._mapId, () -> {
                            NpcInstance retry = MonsterSpawnTable.get().spawnOne(spawn);
                            if (retry != null) {
                                announce(retry);
                            }
                        }));
                return;
            }
            announce(npc);
        }));
    }

    /** 重生秒數 = respawn_delay + rand(0..respawn_delay_random)；生成點查不到用後備值。 */
    private static int delaySecondsOf(SpawnTemplate spawn) {
        if (spawn == null) {
            return DEFAULT_RESPAWN_SECONDS;
        }
        int extra = spawn._respawnDelayRandom > 0
                ? ThreadLocalRandom.current().nextInt(spawn._respawnDelayRandom + 1)
                : 0;
        return spawn._respawnDelay + extra;
    }

    /**
     * 通知這張圖上的玩家有新怪出現。
     * <p>
     * 只送這一隻：S_MONSTER_PACK 在前端是逐筆 upsert，一筆的封包就等於「新增一隻」，
     * 不必每次重生都把整張圖的怪重送一遍。
     */
    private static void announce(NpcInstance npc) {
        PacketSender.broadcastToMap(npc.getMapId(), S_MonsterPack.ofOne(npc));
        _log.info("怪物重生 {} 於地圖{} ({},{})", npc.getName(), npc.getMapId(), npc.getX(), npc.getY());
    }
}
