package com.xin.server.model.ai;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ThreadLocalRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.MapTable;
import com.xin.server.model.Combat;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_BubbleDialog;
import com.xin.server.packet.server.S_HpUpdate;
import com.xin.server.template.MapTemplate;
import com.xin.server.thread.ThreadPoolManager;
import com.xin.server.types.NpcType;
import com.xin.server.world.MapGrid;
import com.xin.server.world.MapLocks;
import com.xin.server.world.WorldMapGrid;
import com.xin.server.world.WorldNpc;

/**
 * 一隻 NPC 的 AI：自己排程自己。
 * <p>
 * 每次 {@link #decide} 決定這一步做什麼，並回傳「幾毫秒後再想一次」；
 * {@link #run} 依回傳值把自己重新排進 NPC 執行緒池。回傳 {@link #STOP} 就不再排程（休眠），
 * 由 {@link AiManager} 在玩家靠近或被攻擊時重新喚醒。
 * <p>
 * 與以前的全域迴圈（每 800ms 掃全世界所有 NPC）相比：每隻怪有自己的移動與攻擊速度，
 * 沒有玩家的地方完全不耗 CPU。
 * <p>
 * <b>每一個分支都必須回傳睡眠時間。</b>L1J 的實戰教訓：漏掉一條路徑、讓睡眠時間
 * 沿用舊值或變成 0，怪物就會原地抽搐或空轉。
 */
public final class NpcAi implements Runnable {

    private static final Logger _log = LoggerFactory.getLogger(NpcAi.class);

    /** 不再排程（休眠）。 */
    static final long STOP = -1;

    /** 目標超過這個距離就放棄。 */
    static final int DROP_TARGET_RANGE = 20;
    /** 察覺範圍外再多這麼多格內還有玩家，就保持清醒（遊走），否則休眠。 */
    static final int WAKE_MARGIN = 8;
    /** 閒置遊走離家的最大距離。 */
    static final int WANDER_RADIUS = 3;
    /** 連續走不動幾次就放棄目標（追擊）或瞬移回家（回家）。 */
    static final int STUCK_LIMIT = 4;
    /** 回家時的放棄距離。 */
    static final int RETURN_GIVE_UP = 60;
    /** 最短睡眠：避免任何分支意外回傳 0 造成空轉。 */
    static final long MIN_SLEEP_MS = 50;
    /** 出錯後隔多久再試。 */
    static final long ERROR_RETRY_MS = 2000;

    /** 非怪物 NPC：玩家在這個距離內就轉身面對。 */
    static final int NPC_FACE_RANGE = 3;
    /** 非怪物 NPC：玩家在這個距離內就保持清醒。 */
    static final int NPC_WAKE_RANGE = 12;
    /** 非怪物 NPC：兩次閒聊的最短間隔。 */
    static final long CHAT_INTERVAL_MS = 20_000;

    private final long _objId;
    private final int _mapId;
    private volatile boolean _cancelled;
    private volatile ScheduledFuture<?> _future;

    NpcAi(long objId, int mapId) {
        _objId = objId;
        _mapId = mapId;
    }

    long objId() {
        return _objId;
    }

    int mapId() {
        return _mapId;
    }

    /** 立即執行第一次。 */
    void start() {
        if (ThreadPoolManager.get().npc().execute("ai:" + _objId, this) == null) {
            AiManager.finished(this);
        }
    }

    /** 停止：已排程的下一次不會執行。 */
    void cancel() {
        _cancelled = true;
        ScheduledFuture<?> f = _future;
        if (f != null) {
            f.cancel(false);
        }
    }

    @Override
    public void run() {
        if (_cancelled) {
            return;
        }
        NpcInstance npc = WorldNpc.get().get(_objId);
        if (npc == null) {
            AiManager.finished(this);
            return;
        }
        long sleep;
        try {
            sleep = MapLocks.call(_mapId, () -> _cancelled ? STOP : decide(npc));
        } catch (RuntimeException e) {
            // 不讓一次例外把這隻怪的 AI 永久停掉
            _log.error("NPC {}（{}）的 AI 發生例外，{}ms 後再試", _objId, npc.getName(), ERROR_RETRY_MS, e);
            sleep = ERROR_RETRY_MS;
        }
        if (sleep < 0 || _cancelled) {
            AiManager.finished(this);
            return;
        }
        _future = ThreadPoolManager.get().npc().schedule("ai:" + _objId, Math.max(MIN_SLEEP_MS, sleep), this);
        if (_future == null) {
            AiManager.finished(this);   // 伺服器關閉中
        }
    }

    // ── 決策 ─────────────────────────────────────────────────────

    /** 回傳幾毫秒後再想一次；{@link #STOP} 表示休眠。呼叫端持有地圖鎖。 */
    long decide(NpcInstance npc) {
        if (npc.getCurrentHp() <= 0 || npc.getAiState() == AiState.DEAD) {
            return STOP;
        }
        MapGrid grid = WorldMapGrid.get().get(npc.getMapId());
        if (grid == null) {
            return STOP;
        }
        List<PcInstance> players = AiManager.playersOn(npc.getMapId());
        PathFinder.Passable passable = passable(grid, players);
        if (npc.getType() == NpcType.MONSTER) {
            return decideMonster(npc, players, passable);
        }
        if (NpcType.isTalkable(npc.getType())) {
            return decideNpc(npc, players, passable);
        }
        return STOP;   // 採集物、裝飾不需要 AI
    }

    private long decideMonster(NpcInstance npc, List<PcInstance> players, PathFinder.Passable passable) {
        long now = System.currentTimeMillis();

        // 1. 回家途中不理會玩家，走到家為止
        if (npc.getAiState() == AiState.RETURN) {
            return walkHome(npc, passable);
        }

        // 2. 牽引：被拉離家太遠就脫戰
        if (npc.getMovementDistance() > 0 && npc.distanceFromHome() > npc.getMovementDistance()) {
            startReturn(npc);
            return walkHome(npc, passable);
        }

        // 3. 選目標：仇恨表最高的有效玩家；沒有的話主動怪找察覺範圍內最近的
        boolean safe = isSafeZone(npc.getMapId());
        PcInstance target = safe ? null : pickTarget(npc, players);
        if (target == null && !safe && npc.isAgro()) {
            target = nearest(npc, players, npc.getAgroRange());
            if (target != null) {
                npc.getHate().add(target.getId(), 0);
            }
        }

        // 4. 沒有目標
        if (target == null) {
            int prev = npc.getAiState();
            if (prev == AiState.CHASE || prev == AiState.ATTACK) {
                startReturn(npc);        // 剛丟掉目標：先回家
                return walkHome(npc, passable);
            }
            if (nearest(npc, players, npc.getAgroRange() + WAKE_MARGIN) == null) {
                if (npc.distanceFromHome() > 1) {
                    startReturn(npc);
                    return walkHome(npc, passable);
                }
                npc.setAiState(AiState.IDLE);
                return STOP;             // 附近沒人：休眠
            }
            return wander(npc, passable);
        }

        // 5. 在攻擊距離內就打，否則追
        int dist = Combat.distance(npc.getX(), npc.getY(), target.getX(), target.getY());
        if (dist <= npc.getRanged()) {
            return attack(npc, target, now);
        }
        return chase(npc, target, passable);
    }

    private long decideNpc(NpcInstance npc, List<PcInstance> players, PathFinder.Passable passable) {
        PcInstance near = nearest(npc, players, NPC_FACE_RANGE);
        if (near != null) {
            // 有人靠近：轉身面對，偶爾說句話
            npc.setAiState(AiState.IDLE);
            NpcMove.faceToward(npc, near.getX(), near.getY());
            maybeChat(npc);
            return 1500 + ThreadLocalRandom.current().nextInt(1000);
        }
        if (nearest(npc, players, NPC_WAKE_RANGE) == null) {
            npc.setAiState(AiState.IDLE);
            return STOP;
        }
        maybeChat(npc);
        return wander(npc, passable);
    }

    // ── 行為 ─────────────────────────────────────────────────────

    private long attack(NpcInstance npc, PcInstance target, long now) {
        npc.setAiState(AiState.ATTACK);
        npc.setStuckCount(0);
        if (now < npc.getNextAttackAt()) {
            // 冷卻中：原地等，不要改成移動（那會變成貼身來回抖動）
            return npc.getNextAttackAt() - now;
        }
        int heading = PathFinder.headingOf(target.getX() - npc.getX(), target.getY() - npc.getY());
        if (heading >= 0) {
            npc.setHeading(heading);   // 前端播攻擊時會自己轉向，這裡只記錄
        }
        Combat.monsterAttack(npc, target);
        npc.setNextAttackAt(now + npc.getAtkSpeed());
        return npc.getAtkSpeed();
    }

    private long chase(NpcInstance npc, PcInstance target, PathFinder.Passable passable) {
        npc.setAiState(AiState.CHASE);
        int giveUp = Math.max(DROP_TARGET_RANGE, npc.getAgroRange() * 2);
        int[] step = PathFinder.nextStep(npc.getX(), npc.getY(), target.getX(), target.getY(),
                npc.getRanged(), giveUp, passable);
        if (step == null) {
            int stuck = npc.getStuckCount() + 1;
            npc.setStuckCount(stuck);
            if (stuck > STUCK_LIMIT) {
                // 一直走不到：放棄這個目標，改找仇恨表的下一個（沒有就會回家）
                npc.getHate().remove(target.getId());
                npc.setStuckCount(0);
            }
            return npc.getPassiSpeed() * 2L;   // 被擋住就退一步等，不要原地空轉
        }
        npc.setStuckCount(0);
        NpcMove.step(npc, step[0], step[1]);
        return npc.getPassiSpeed();
    }

    private void startReturn(NpcInstance npc) {
        npc.getHate().clear();
        npc.setAiState(AiState.RETURN);
        npc.setStuckCount(0);
    }

    private long walkHome(NpcInstance npc, PathFinder.Passable passable) {
        if (npc.distanceFromHome() <= 1) {
            arriveHome(npc);
            return idleSleep();
        }
        int[] step = PathFinder.nextStep(npc.getX(), npc.getY(), npc.getHomeX(), npc.getHomeY(),
                1, RETURN_GIVE_UP, passable);
        if (step == null) {
            int stuck = npc.getStuckCount() + 1;
            npc.setStuckCount(stuck);
            if (stuck > STUCK_LIMIT) {
                // 回不去（路被堵死、或被拉到很遠）：直接瞬移回家，不要永遠卡在半路
                MapGrid grid = WorldMapGrid.get().get(npc.getMapId());
                if (grid != null && grid.isFree(npc.getHomeX(), npc.getHomeY())) {
                    NpcMove.teleport(npc, npc.getHomeX(), npc.getHomeY());
                }
                arriveHome(npc);
                return idleSleep();
            }
            return npc.getPassiSpeed() * 2L;
        }
        npc.setStuckCount(0);
        NpcMove.step(npc, step[0], step[1]);
        return npc.getPassiSpeed();
    }

    /** 到家：回滿血、清仇恨。脫戰的代價是「白打了」，不然玩家可以來回拉怪慢慢磨死。 */
    private void arriveHome(NpcInstance npc) {
        npc.setAiState(AiState.IDLE);
        npc.setStuckCount(0);
        npc.getHate().clear();
        if (npc.getCurrentHp() < npc.getMaxHp()) {
            npc.setCurrentHp(npc.getMaxHp());
            PacketSender.broadcastToMap(npc.getMapId(),
                    S_HpUpdate.of(npc.getId(), npc.getCurrentHp(), npc.getMaxHp()));
        }
    }

    /** 閒置遊走：不超出家附近，常常只是站著（一直走看起來反而像在抽搐）。 */
    private long wander(NpcInstance npc, PathFinder.Passable passable) {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        if (!npc.isWander() || rnd.nextInt(100) < 60) {
            npc.setAiState(AiState.IDLE);
            return idleSleep();
        }
        int radius = npc.getMovementDistance() > 0
                ? Math.min(WANDER_RADIUS, npc.getMovementDistance())
                : WANDER_RADIUS;
        int start = rnd.nextInt(8);
        for (int i = 0; i < 8; i++) {
            int[] d = PathFinder.delta(start + i);
            int nx = npc.getX() + d[0];
            int ny = npc.getY() + d[1];
            if (npc.getMapId() != npc.getHomeMapId()
                    || PathFinder.distance(nx, ny, npc.getHomeX(), npc.getHomeY()) > radius) {
                continue;
            }
            if (!PathFinder.canStep(npc.getX(), npc.getY(), d[0], d[1], passable)) {
                continue;
            }
            npc.setAiState(AiState.WANDER);
            NpcMove.step(npc, nx, ny);
            return npc.getPassiSpeed() + rnd.nextInt(Math.max(1, npc.getPassiSpeed()));
        }
        npc.setAiState(AiState.IDLE);
        return idleSleep();
    }

    private void maybeChat(NpcInstance npc) {
        String chat = npc.getIdleChat();
        if (chat == null || chat.isBlank()) {
            return;
        }
        long now = System.currentTimeMillis();
        if (now - npc.getLastChatAt() < CHAT_INTERVAL_MS
                || ThreadLocalRandom.current().nextInt(100) >= 25) {
            return;
        }
        String[] lines = chat.split("\\|");
        String line = lines[ThreadLocalRandom.current().nextInt(lines.length)].trim();
        if (line.isEmpty()) {
            return;
        }
        npc.setLastChatAt(now);
        PacketSender.broadcastToMap(npc.getMapId(), S_BubbleDialog.of(npc.getId(), npc.getName(), line));
    }

    // ── 目標 ─────────────────────────────────────────────────────

    /** 仇恨表最高而且仍然有效的玩家；無效的一路清掉，改看下一個。 */
    private PcInstance pickTarget(NpcInstance npc, List<PcInstance> players) {
        while (!npc.getHate().isEmpty()) {
            long id = npc.getHate().top();
            PcInstance pc = find(players, id);
            if (pc != null && Combat.distance(npc.getX(), npc.getY(), pc.getX(), pc.getY()) <= DROP_TARGET_RANGE) {
                return pc;
            }
            npc.getHate().remove(id);   // 下線、死亡、換圖、跑太遠
        }
        return null;
    }

    private static PcInstance find(List<PcInstance> players, long objId) {
        for (PcInstance pc : players) {
            if (pc.getId() == objId) {
                return pc;
            }
        }
        return null;
    }

    private static PcInstance nearest(NpcInstance npc, List<PcInstance> players, int range) {
        PcInstance best = null;
        int bestDist = Integer.MAX_VALUE;
        for (PcInstance pc : players) {
            int d = Combat.distance(npc.getX(), npc.getY(), pc.getX(), pc.getY());
            if (d <= range && d < bestDist) {
                best = pc;
                bestDist = d;
            }
        }
        return best;
    }

    // ── 工具 ─────────────────────────────────────────────────────

    /** 能站的格子：地形可走、沒有別的 NPC、也沒有玩家站著。 */
    private static PathFinder.Passable passable(MapGrid grid, List<PcInstance> players) {
        Set<Long> pcCells = new HashSet<>();
        for (PcInstance pc : players) {
            pcCells.add(cellKey(pc.getX(), pc.getY()));
        }
        return (x, y) -> grid.isFree(x, y) && !pcCells.contains(cellKey(x, y));
    }

    private static long cellKey(int x, int y) {
        return ((long) x << 32) | (y & 0xffffffffL);
    }

    private static boolean isSafeZone(int mapId) {
        MapTemplate map = MapTable.get().getMap(mapId);
        return map != null && map._safeZone;
    }

    private static long idleSleep() {
        return 1500 + ThreadLocalRandom.current().nextInt(2000);
    }
}
