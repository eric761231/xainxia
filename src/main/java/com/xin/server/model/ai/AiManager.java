package com.xin.server.model.ai;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.Combat;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.ClientManager;
import com.xin.server.thread.ThreadPoolManager;
import com.xin.server.types.NpcType;
import com.xin.server.world.MapGrid;
import com.xin.server.world.MapLocks;
import com.xin.server.world.WorldMapGrid;
import com.xin.server.world.WorldNpc;

/**
 * NPC AI 的管理：誰醒著、何時叫醒、何時休眠。
 * <p>
 * 每隻 NPC 的 AI（{@link NpcAi}）自己排程自己；這裡只有兩件週期性的事：
 * <ul>
 *   <li>每秒一次的<b>喚醒巡檢</b>：只看有玩家的地圖，把玩家附近沉睡的 NPC 叫醒。
 *       沒有玩家的地方完全不耗 CPU。</li>
 *   <li>每分鐘一次的<b>占位重建</b>：用目前活著的 NPC 重建生物占位格並記錄差異。
 *       漏掉任何一處 enter/leave 都會留下一格看不見的牆，定期重建比事後追查可靠。</li>
 * </ul>
 * 被攻擊時由 {@link Combat} 直接呼叫 {@link #wake}，立刻反擊，不必等巡檢。
 */
public final class AiManager {

    private static final Logger _log = LoggerFactory.getLogger(AiManager.class);

    private static final long SWEEP_MS = 1000;
    private static final long RECONCILE_MS = 60_000;

    private static final AtomicBoolean STARTED = new AtomicBoolean(false);

    /** 醒著的 AI，key = NPC objId。 */
    private static final ConcurrentHashMap<Long, NpcAi> RUNNING = new ConcurrentHashMap<>();

    private AiManager() {
    }

    public static void start() {
        if (!STARTED.compareAndSet(false, true)) {
            return;
        }
        ThreadPoolManager.get().npc().scheduleWithFixedDelay("ai-sweep", SWEEP_MS, SWEEP_MS, AiManager::sweep);
        ThreadPoolManager.get().npc().scheduleWithFixedDelay("ai-reconcile", RECONCILE_MS, RECONCILE_MS,
                AiManager::reconcileMovers);
        _log.info("NPC AI 已啟動（喚醒巡檢每 {}ms，占位重建每 {} 秒）", SWEEP_MS, RECONCILE_MS / 1000);
    }

    /** 叫醒這隻 NPC（已醒著就不做事）。 */
    public static void wake(NpcInstance npc) {
        if (npc == null || npc.getCurrentHp() <= 0 || !hasAi(npc)) {
            return;
        }
        NpcAi ai = new NpcAi(npc.getId(), npc.getMapId());
        if (RUNNING.putIfAbsent(npc.getId(), ai) == null) {
            ai.start();
        }
    }

    /** 停止這隻 NPC 的 AI（死亡、移除時）。這是唯一的註銷入口。 */
    public static void unregister(long objId) {
        NpcAi ai = RUNNING.remove(objId);
        if (ai != null) {
            ai.cancel();
        }
    }

    /** AI 自己決定休眠時呼叫。 */
    static void finished(NpcAi ai) {
        RUNNING.remove(ai.objId(), ai);
    }

    public static boolean isRunning(long objId) {
        return RUNNING.containsKey(objId);
    }

    public static int activeCount() {
        return RUNNING.size();
    }

    /** 讓某張圖上所有醒著的 NPC 休眠（GM 用）。 */
    public static int sleepMap(int mapId) {
        int n = 0;
        for (NpcAi ai : new ArrayList<>(RUNNING.values())) {
            if (ai.mapId() == mapId) {
                unregister(ai.objId());
                n++;
            }
        }
        return n;
    }

    /** 叫醒某張圖上所有 NPC（GM 用）。 */
    public static int wakeMap(int mapId) {
        int n = 0;
        for (NpcInstance npc : WorldNpc.get().getNpcsByMap(mapId)) {
            if (!isRunning(npc.getId()) && npc.getCurrentHp() > 0 && hasAi(npc)) {
                wake(npc);
                n++;
            }
        }
        return n;
    }

    /** 指定地圖上活著、已進入遊戲的玩家。 */
    public static List<PcInstance> playersOn(int mapId) {
        List<PcInstance> out = new ArrayList<>();
        for (Client c : ClientManager.getAll()) {
            if (c.hasActiveChar()) {
                PcInstance pc = c.getActiveChar();
                if (pc.getMapId() == mapId && pc.getCurrentHp() > 0) {
                    out.add(pc);
                }
            }
        }
        return out;
    }

    /** 怪物與可對話的 NPC 才有 AI；採集物與裝飾不需要。 */
    private static boolean hasAi(NpcInstance npc) {
        return npc.getType() == NpcType.MONSTER || NpcType.isTalkable(npc.getType());
    }

    private static int wakeRangeOf(NpcInstance npc) {
        return npc.getType() == NpcType.MONSTER
                ? npc.getAgroRange() + NpcAi.WAKE_MARGIN
                : NpcAi.NPC_WAKE_RANGE;
    }

    /** 每秒：只看有玩家的地圖，把玩家附近沉睡的 NPC 叫醒。 */
    static void sweep() {
        Map<Integer, List<PcInstance>> byMap = new HashMap<>();
        for (Client c : ClientManager.getAll()) {
            if (c.hasActiveChar()) {
                PcInstance pc = c.getActiveChar();
                if (pc.getCurrentHp() > 0) {
                    byMap.computeIfAbsent(pc.getMapId(), k -> new ArrayList<>()).add(pc);
                }
            }
        }
        for (Map.Entry<Integer, List<PcInstance>> e : byMap.entrySet()) {
            for (NpcInstance npc : WorldNpc.get().getNpcsByMap(e.getKey())) {
                if (npc.getCurrentHp() <= 0 || isRunning(npc.getId()) || !hasAi(npc)) {
                    continue;
                }
                int range = wakeRangeOf(npc);
                for (PcInstance pc : e.getValue()) {
                    if (Combat.distance(npc.getX(), npc.getY(), pc.getX(), pc.getY()) <= range) {
                        wake(npc);
                        break;
                    }
                }
            }
        }
    }

    /** 每分鐘：用活著的 NPC 重建生物占位格，有差異就記錄（代表某處漏了 enter/leave）。 */
    static void reconcileMovers() {
        for (MapGrid grid : WorldMapGrid.get().getAll()) {
            MapLocks.run(grid.getMapId(), () -> {
                int before = grid.clearMovers();
                int after = 0;
                for (NpcInstance npc : WorldNpc.get().getNpcsByMap(grid.getMapId())) {
                    if (npc.getCurrentHp() > 0) {
                        grid.enterMover(npc.getId(), npc.getX(), npc.getY());
                        after++;
                    }
                }
                if (before != after) {
                    _log.warn("地圖 {} 的生物占位與實際不符（格上 {} / 實際 {}），已重建",
                            grid.getMapId(), before, after);
                }
            });
        }
    }
}
